const { onCall, onRequest } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { defineSecret } = require('firebase-functions/params');
const { createClient } = require('@supabase/supabase-js');
const { Resend } = require('resend');

initializeApp();

const auth = getAuth();
const db = getFirestore();

// Define secrets
const SUPABASE_URL = defineSecret('SUPABASE_URL');
const SUPABASE_SERVICE_KEY = defineSecret('SUPABASE_SERVICE_KEY');
const RESEND_API_KEY = defineSecret('RESEND_API_KEY');

// HTTP function
exports.helloWorld = onRequest({ region: 'us-central1' }, (req, res) => {
  res.send('Hello from Firebase');
});

// Firestore triggers
exports.syncMarketingConsent = onDocumentWritten({
  document: 'users/{uid}',
  region: 'us-central1',
  secrets: [SUPABASE_URL, SUPABASE_SERVICE_KEY]
}, async (event) => {
  // Initialize Supabase inside the function with secrets
  const supabase = createClient(
    SUPABASE_URL.value(),
    SUPABASE_SERVICE_KEY.value()
  );
  
  const after = event.data?.after?.data();
  const before = event.data?.before?.data();
  if (!after?.email) return null;
  
  try {
    const { data: existing } = await supabase
      .from('users_email')
      .select('id')
      .eq('email', after.email.trim().toLowerCase())
      .single();

    if (existing) {
      const { error } = await supabase
        .from('users_email')
        .update({
          firebase_uid: event.params.uid,
          marketing_consent: after.marketing_consent || false,
          marketing_consent_date: after.marketing_consent ? new Date().toISOString() : null,
          email_type: after.marketing_consent ? 'both' : 'user',
          status: 'active',
          email_verified: after.email_verified || false,
        })
        .eq('email', after.email.trim().toLowerCase());
      
      if (error) throw error;
    } else {
      const { error } = await supabase
        .from('users_email')
        .insert({
          email: after.email.trim().toLowerCase(),
          firebase_uid: event.params.uid,
          marketing_consent: after.marketing_consent || false,
          marketing_consent_date: after.marketing_consent ? new Date().toISOString() : null,
          email_type: after.marketing_consent ? 'both' : 'user',
          status: 'active',
          source: 'peakfit_app',
          email_verified: after.email_verified || false,
        });
      
      if (error) throw error;
    }
    console.log('Marketing consent synced for', after.email);
  } catch (err) {
    console.error('Supabase sync error', JSON.stringify(err));
  }
  return null;
});

exports.onVerificationCodeCreated = onDocumentWritten({
  document: 'verifications/{email}',
  region: 'us-central1',
  secrets: [RESEND_API_KEY]
}, async (event) => {
  const data = event.data?.after?.data();
  if (!data) return null;

  console.log(`Verification code ${data.code} for ${data.email}`);

  // Initialize Resend inside the function
  const resend = new Resend(RESEND_API_KEY.value());

  try {
    const { data: result, error } = await resend.emails.send({
      from: 'PeakFit <noreply@peakfit.ai>',
      to: [data.email],
      subject: 'Your PeakFit Verification Code',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="margin: 0; font-size: 32px; font-weight: 300; letter-spacing: 2px;">PEAKFIT</h1>
            <p style="margin: 10px 0 0 0; opacity: 0.9;">Elite Fitness Awaits</p>
          </div>
          <div style="background: white; padding: 40px; border: 1px solid #e0e0e0; border-top: none;">
            <h2 style="color: #333; margin-bottom: 20px;">Verify Your Email</h2>
            <p style="color: #666; line-height: 1.6;">Your verification code is:</p>
            <div style="background: #f8f9fa; border: 2px dashed #dee2e6; border-radius: 8px; padding: 30px; text-align: center; margin: 30px 0;">
              <div style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #495057;">${data.code}</div>
            </div>
            <p style="color: #666; line-height: 1.6;">This code will expire in 15 minutes.</p>
          </div>
        </div>
      `
    });

    if (error) {
      console.error('Failed to send verification email:', error);
    } else {
      console.log('Verification email sent successfully to', data.email);
    }
  } catch (err) {
    console.error('Resend error:', err);
  }

  return null;
});

exports.onPasswordResetCodeCreated = onDocumentWritten({
  document: 'password_resets/{email}',
  region: 'us-central1',
  secrets: [RESEND_API_KEY]
}, async (event) => {
  const data = event.data?.after?.data();
  if (!data) return null;

  console.log(`Password reset code ${data.code} for ${data.email}`);

  // Initialize Resend inside the function
  const resend = new Resend(RESEND_API_KEY.value());

  try {
    const { data: result, error } = await resend.emails.send({
      from: 'PeakFit <noreply@peakfit.ai>',
      to: [data.email],
      subject: 'Reset Your PeakFit Password',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="margin: 0; font-size: 32px; font-weight: 300; letter-spacing: 2px;">PEAKFIT</h1>
          </div>
          <div style="background: white; padding: 40px; border: 1px solid #e0e0e0; border-top: none;">
            <h2 style="color: #333; margin-bottom: 20px;">Password Reset</h2>
            <p style="color: #666; line-height: 1.6;">Your password reset code is:</p>
            <div style="background: #f8f9fa; border: 2px dashed #dee2e6; border-radius: 8px; padding: 30px; text-align: center; margin: 30px 0;">
              <div style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #495057;">${data.code}</div>
            </div>
            <p style="color: #666; line-height: 1.6;">This code will expire in 15 minutes.</p>
            <p style="color: #999; font-size: 14px; margin-top: 30px;">If you didn't request this, please ignore this email.</p>
          </div>
        </div>
      `
    });

    if (error) {
      console.error('Failed to send password reset email:', error);
    } else {
      console.log('Password reset email sent successfully to', data.email);
    }
  } catch (err) {
    console.error('Resend error:', err);
  }

  return null;
});

// Callable function
exports.resetPasswordWithCode = onCall({ region: 'us-central1' }, async (request) => {
  const { email, code, newPassword } = request.data;
  
  if (!email || !code || !newPassword) {
    throw new Error('Missing required fields');
  }
  
  const normalizedEmail = email.trim().toLowerCase();
  
  try {
    const snap = await db.collection('password_resets').doc(normalizedEmail).get();
    
    if (!snap.exists) {
      throw new Error('No password reset request found for this email');
    }
    
    if (snap.data().code !== code.trim()) {
      throw new Error('Invalid reset code');
    }
    
    let user;
    try {
      user = await auth.getUserByEmail(normalizedEmail);
    } catch (authError) {
      console.error('Error getting user by email:', authError);
      
      const usersSnapshot = await db
        .collection('users')
        .where('email', '==', normalizedEmail)
        .limit(1)
        .get();
      
      if (usersSnapshot.empty) {
        throw new Error('No user account found with this email address');
      }
      
      const userId = usersSnapshot.docs[0].id;
      try {
        user = await auth.getUser(userId);
      } catch (e) {
        throw new Error('User account not found in authentication system');
      }
    }
    
    await auth.updateUser(user.uid, { password: newPassword });
    await snap.ref.delete();
    
    console.log(`Password reset successful for user: ${normalizedEmail}`);
    return { success: true };
    
  } catch (err) {
    console.error('Password reset error:', err);
    throw new Error(err.message || 'Failed to reset password. Please try again.');
  }
});

// Scheduled function
exports.cleanupOldVerificationCodes = onSchedule({
  schedule: 'every 15 minutes',
  region: 'us-central1'
}, async (event) => {
  const expiry = new Date(Date.now() - 15 * 60 * 1000);
  
  const verifications = await db.collection('verifications')
    .where('created_at', '<', expiry)
    .get();
  
  const resets = await db.collection('password_resets')
    .where('created_at', '<', expiry)
    .get();
  
  const batch = db.batch();
  [...verifications.docs, ...resets.docs].forEach((doc) => batch.delete(doc.ref));
  
  await batch.commit();
  console.log(`Cleaned up ${verifications.size + resets.size} expired codes`);
  
  return null;
});