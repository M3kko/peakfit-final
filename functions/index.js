const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
const functions = require('firebase-functions');

initializeApp();

const cfg = functions.config().supabase || {};
if (!cfg.url || !cfg.service_key) throw new Error('Supabase config missing');
const supabase = createClient(cfg.url, cfg.service_key, {
  auth: { persistSession: false },
  global: { fetch },
});

async function must(promise) {
  const { data, error } = await promise;
  if (error) throw error;
  return data;
}

exports.helloWorld = onRequest({ region: 'us-central1' }, (req, res) => {
  res.send('ok');
});

exports.syncMarketingConsent = onDocumentWritten(
  { document: 'users/{uid}', region: 'us-central1' },
  async (event) => {
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();
    if (!after || after.marketing_consent === before?.marketing_consent) return;
    const row = {
      email: after.email,
      firebase_uid: event.params.uid,
      status: after.marketing_consent ? 'active' : 'unsubscribed',
      subscribed_at: after.marketing_consent ? new Date().toISOString() : null,
      unsubscribed_at: after.marketing_consent ? null : new Date().toISOString(),
      source: 'peakfit_app',
    };
    try {
      await must(
        supabase
          .from('marketing_subscribers')
          .upsert(row, { onConflict: 'email' })
      );
    } catch (err) {
      console.error('supabase upsert failed', err);
    }
  }
);

exports.resetPasswordWithCode = onCall({ region: 'us-central1' }, async (req) => {
  const { email, code, newPassword } = req.data || {};
  if (!email || !code || !newPassword) throw new HttpsError('invalid-argument', 'missing');
  const snap = await admin.firestore().collection('password_resets').doc(email).get();
  if (!snap.exists || snap.data().code !== code) throw new HttpsError('permission-denied', 'bad-code');
  const user = await admin.auth().getUserByEmail(email);
  await admin.auth().updateUser(user.uid, { password: newPassword });
  await snap.ref.delete();
  return { success: true };
});

exports.cleanupOldVerificationCodes = onSchedule(
  { schedule: 'every 15 minutes', region: 'us-central1' },
  async () => {
    const db = admin.firestore();
    const cutoff = new Date(Date.now() - 15 * 60 * 1000);
    for (const col of ['verifications', 'password_resets']) {
      const docs = await db.collection(col).where('created_at', '<', cutoff).get();
      const batch = db.batch();
      docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();
    }
  }
);
