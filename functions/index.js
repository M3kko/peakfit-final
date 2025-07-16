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
        email: after.email,
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
      }).eq('email', after.email);
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
  if (!email || !code || !newPassword) throw new HttpsError('invalid-argument', 'Missing fields');
  try {
    const snap = await admin.firestore().collection('password_resets').doc(email).get();
    if (!snap.exists || snap.data().code !== code) throw new HttpsError('permission-denied', 'Bad code');
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(user.uid, { password: newPassword });
    await snap.ref.delete();
    return { success: true };
  } catch (err) {
    console.error('Reset error', err);
    if (err instanceof HttpsError) throw err;
    throw new HttpsError('internal', 'Reset failed');
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
});
