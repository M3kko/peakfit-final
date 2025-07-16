const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
const functions = require('firebase-functions');

initializeApp();

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

exports.helloWorld = onRequest({ region: 'us-central1' }, (req, res) => {
  res.send('Hello from Firebase');
});

exports.syncMarketingConsent = onDocumentWritten({ document: 'users/{uid}', region: 'us-central1' }, async (e) => {
  if (!supabase) return null;
  const after = e.data?.after?.data();
  const before = e.data?.before?.data();
  if (!after?.email || after.marketing_consent === before?.marketing_consent) return null;
  
  const table = supabase.from('marketing_subscribers');
  try {
    if (after.marketing_consent) {
      const { error } = await table.upsert({
        email: after.email.trim().toLowerCase(),
        firebase_uid: e.params.uid,
        status: 'active',
        source: 'peakfit_app',
        subscribed_at: new Date().toISOString(),
      }, { onConflict: 'email' });
      if (error) throw error;
    } else {
      const { error } = await table.update({
        status: 'unsubscribed',
        unsubscribed_at: new Date().toISOString(),
      }).eq('email', after.email.trim().toLowerCase());
      if (error) throw error;
    }
  } catch (err) {
    console.error('Supabase sync error', JSON.stringify(err));
  }
  return null;
});

exports.logVerificationCode = onDocumentWritten({ document: 'verifications/{email}', region: 'us-central1' }, (evt) => {
  const d = evt.data?.after?.data();
  if (d) console.log(`Verification code ${d.code} for ${d.email}`);
  return null;
});

exports.logPasswordResetCode = onDocumentWritten({ document: 'password_resets/{email}', region: 'us-central1' }, (evt) => {
  const d = evt.data?.after?.data();
  if (d) console.log(`Password reset code ${d.code} for ${d.email}`);
  return null;
});

exports.resetPasswordWithCode = onCall({ region: 'us-central1' }, async (req) => {
  const { email, code, newPassword } = req.data || {};
  
  if (!email || !code || !newPassword) {
    throw new HttpsError('invalid-argument', 'Missing required fields');
  }
  
  // Normalize email (trim and lowercase)
  const normalizedEmail = email.trim().toLowerCase();
  
  try {
    // Check if the reset code is valid
    const snap = await admin.firestore().collection('password_resets').doc(normalizedEmail).get();
    
    if (!snap.exists) {
      throw new HttpsError('not-found', 'No password reset request found for this email');
    }
    
    if (snap.data().code !== code.trim()) {
      throw new HttpsError('permission-denied', 'Invalid reset code');
    }
    
    // Try to get the user by email
    let user;
    try {
      user = await admin.auth().getUserByEmail(normalizedEmail);
    } catch (authError) {
      console.error('Error getting user by email:', authError);
      
      // If user not found by email, try to find them in Firestore
      const usersSnapshot = await admin.firestore()
        .collection('users')
        .where('email', '==', normalizedEmail)
        .limit(1)
        .get();
      
      if (usersSnapshot.empty) {
        throw new HttpsError('not-found', 'No user account found with this email address');
      }
      
      // Get the user ID from Firestore and try again
      const userId = usersSnapshot.docs[0].id;
      try {
        user = await admin.auth().getUser(userId);
      } catch (e) {
        throw new HttpsError('not-found', 'User account not found in authentication system');
      }
    }
    
    // Update the user's password
    await admin.auth().updateUser(user.uid, { password: newPassword });
    
    // Delete the reset code
    await snap.ref.delete();
    
    console.log(`Password reset successful for user: ${normalizedEmail}`);
    return { success: true };
    
  } catch (err) {
    console.error('Password reset error:', err);
    
    if (err instanceof HttpsError) {
      throw err;
    }
    
    throw new HttpsError('internal', 'Failed to reset password. Please try again.');
  }
});

exports.cleanupOldVerificationCodes = onSchedule({ schedule: 'every 15 minutes', region: 'us-central1' }, async () => {
  const db = admin.firestore();
  const expiry = new Date(Date.now() - 15 * 60 * 1000);
  const v = await db.collection('verifications').where('created_at', '<', expiry).get();
  const r = await db.collection('password_resets').where('created_at', '<', expiry).get();
  const batch = db.batch();
  [...v.docs, ...r.docs].forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  console.log(`Cleaned up ${v.size + r.size} expired codes`);
});