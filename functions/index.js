const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
const { Resend } = require('resend');

admin.initializeApp();

// Initialize Supabase
let supabase = null;
try {
  const cfg = functions.config().supabase || {};
  if (cfg.url && cfg.service_key) {
    supabase = createClient(cfg.url, cfg.service_key);
    console.log('Supabase ready');
  } else {
    console.log('Supabase env not set');
  }
} catch (e) {
  console.error('Supabase init failed', e);
}

// Initialize Resend
let resend = null;
if (functions.config().resend?.key) {
  resend = new Resend(functions.config().resend.key);
}

// HTTP function
exports.helloWorld = functions.https.onRequest((req, res) => {
  res.send('Hello from Firebase');
});

// Firestore triggers
exports.syncMarketingConsent = functions.firestore
  .document('users/{uid}')
  .onWrite(async (change, context) => {
    if (!supabase) return null;
    const after = change.after.data();
    const before = change.before.data();
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
            firebase_uid: context.params.uid,
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
            firebase_uid: context.params.uid,
            marketing_consent: after.marketing_consent || false,
            marketing_consent_date: after.marketing_consent ? new Date().toISOString() : null,
            email_type: after.marketing_consent ? 'both' : 'user',
            status: 'active',
            source: 'peakfit_app',
            email_verified: after.email_verified || false,
          });
        
        if (error) throw error;
      }
    } catch (err) {
      console.error('Supabase sync error', JSON.stringify(err));
    }
    return null;
  });

exports.sendVerificationCode = functions.firestore
  .document('verifications/{email}')
  .onWrite(async (change, context) => {
    const data = change.after.data();
    if (!data) return null;

    if (!resend) {
      console.log(`Verification code ${data.code} for ${data.email} (Resend not configured)`);
      return null;
    }

    try {
      const { data: result, error } = await resend.emails.send({
        from: 'PeakFit <noreply@yourverifieddomain.com>', // Replace with your domain
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
        console.log('Verification email sent:', result);
      }
    } catch (err) {
      console.error('Resend error:', err);
    }

    return null;
  });

exports.sendPasswordResetCode = functions.firestore
  .document('password_resets/{email}')
  .onWrite(async (change, context) => {
    const data = change.after.data();
    if (!data) return null;

    if (!resend) {
      console.log(`Password reset code ${data.code} for ${data.email} (Resend not configured)`);
      return null;
    }

    try {
      const { data: result, error } = await resend.emails.send({
        from: 'PeakFit <noreply@yourverifieddomain.com>', // Replace with your domain
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
        console.log('Password reset email sent:', result);
      }
    } catch (err) {
      console.error('Resend error:', err);
    }

    return null;
  });

// Callable function
exports.resetPasswordWithCode = functions.https.onCall(async (data, context) => {
  const { email, code, newPassword } = data;
  
  if (!email || !code || !newPassword) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }
  
  const normalizedEmail = email.trim().toLowerCase();
  
  try {
    const snap = await admin.firestore().collection('password_resets').doc(normalizedEmail).get();
    
    if (!snap.exists) {
      throw new functions.https.HttpsError('not-found', 'No password reset request found for this email');
    }
    
    if (snap.data().code !== code.trim()) {
      throw new functions.https.HttpsError('permission-denied', 'Invalid reset code');
    }
    
    let user;
    try {
      user = await admin.auth().getUserByEmail(normalizedEmail);
    } catch (authError) {
      console.error('Error getting user by email:', authError);
      
      const usersSnapshot = await admin.firestore()
        .collection('users')
        .where('email', '==', normalizedEmail)
        .limit(1)
        .get();
      
      if (usersSnapshot.empty) {
        throw new functions.https.HttpsError('not-found', 'No user account found with this email address');
      }
      
      const userId = usersSnapshot.docs[0].id;
      try {
        user = await admin.auth().getUser(userId);
      } catch (e) {
        throw new functions.https.HttpsError('not-found', 'User account not found in authentication system');
      }
    }
    
    await admin.auth().updateUser(user.uid, { password: newPassword });
    await snap.ref.delete();
    
    console.log(`Password reset successful for user: ${normalizedEmail}`);
    return { success: true };
    
  } catch (err) {
    console.error('Password reset error:', err);
    
    if (err.code && err.code.startsWith('auth/')) {
      throw err;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to reset password. Please try again.');
  }
});

// Scheduled function
exports.cleanupOldVerificationCodes = functions.pubsub
  .schedule('every 15 minutes')
  .onRun(async (context) => {
    const db = admin.firestore();
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