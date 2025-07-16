// ───────────────────────────────────────────────────────────────────────────────
//  Firebase + Supabase Cloud Functions (v2) – PeakFit
// ───────────────────────────────────────────────────────────────────────────────
//
//  • helloWorld                   simple HTTP test
//  • syncMarketingConsent         Firestore → Supabase sync
//  • logVerificationCode          dev-only logging
//  • logPasswordResetCode         dev-only logging
//  • resetPasswordWithCode        *** CALLABLE ***  <— fixed
//  • cleanupOldVerificationCodes  scheduled cleanup
//
//  Deps: firebase-functions v4+, firebase-admin, @supabase/supabase-js
// ───────────────────────────────────────────────────────────────────────────────

const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');
const functions = require('firebase-functions'); // only for runtime config

// ── Firebase Admin ────────────────────────────────────────────────────────────
initializeApp();

// ── Supabase (Marketing list) ────────────────────────────────────────────────
let supabase = null;
try {
  const cfg = functions.config().supabase || {};
  if (cfg.url && cfg.service_key) {
    supabase = createClient(cfg.url, cfg.service_key);
    console.log('🔗 Supabase initialized');
  } else {
    console.log('⚠️  Supabase config not set');
  }
} catch (err) {
  console.error('❌ Supabase init error:', err);
}

// ──────────────────────────────────────────────────────────────────────────────
//  1. Simple ping
// ──────────────────────────────────────────────────────────────────────────────
exports.helloWorld = onRequest(
  { region: 'us-central1' },
  (req, res) => res.send('Hello from Firebase v6 with Supabase!')
);

// ──────────────────────────────────────────────────────────────────────────────
//  2. Marketing-consent sync – Firestore → Supabase
// ──────────────────────────────────────────────────────────────────────────────
exports.syncMarketingConsent = onDocumentWritten(
  { document: 'users/{userId}', region: 'us-central1' },
  async (event) => {
    const after  = event.data?.after?.data();
    const before = event.data?.before?.data();
    const uid    = event.params.userId;

    if (!after?.email || !supabase) return null;
    if (after.marketing_consent === before?.marketing_consent) return null;

    try {
      if (after.marketing_consent) {
        await supabase.from('marketing_subscribers').upsert({
          email:        after.email,
          firebase_uid: uid,
          subscribed_at: new Date().toISOString(),
          status:       'active',
          source:       'peakfit_app',
        }, { onConflict: 'email' });
        console.log(`✅ Subscribed ${after.email}`);
      } else {
        await supabase.from('marketing_subscribers')
          .update({
            status: 'unsubscribed',
            unsubscribed_at: new Date().toISOString(),
          })
          .eq('email', after.email);
        console.log(`🚫 Unsubscribed ${after.email}`);
      }
    } catch (err) {
      console.error('❌ Supabase sync error:', err);
    }
    return null;
  }
);

// ──────────────────────────────────────────────────────────────────────────────
//  3. Dev-only logging (replace with real e-mail/SMS in prod)
// ──────────────────────────────────────────────────────────────────────────────
exports.logVerificationCode = onDocumentWritten(
  { document: 'verifications/{email}', region: 'us-central1' },
  (event) => {
    const d = event.data?.after?.data();
    if (d) console.log(`📧 Verification code for ${d.email}: ${d.code}`);
    return null;
  }
);

exports.logPasswordResetCode = onDocumentWritten(
  { document: 'password_resets/{email}', region: 'us-central1' },
  (event) => {
    const d = event.data?.after?.data();
    if (d) console.log(`🔑 Password-reset code for ${d.email}: ${d.code}`);
    return null;
  }
);

// ──────────────────────────────────────────────────────────────────────────────
//  4. Password-reset (CALLABLE) – fixed payload handling
// ──────────────────────────────────────────────────────────────────────────────
exports.resetPasswordWithCode = onCall(
  { region: 'us-central1' },
  async (request) => {
    const { email, code, newPassword } = request.data || {};

    // Basic validation
    if (!email || !code || !newPassword) {
      throw new HttpsError('invalid-argument', 'Missing required fields');
    }

    try {
      // 1. Verify reset code
      const snap = await admin.firestore()
        .collection('password_resets')
        .doc(email)
        .get();

      if (!snap.exists || snap.data().code !== code) {
        throw new HttpsError('permission-denied', 'Invalid reset code');
      }

      // 2. Update password
      const user = await admin.auth().getUserByEmail(email);
      await admin.auth().updateUser(user.uid, { password: newPassword });

      // 3. Clean up
      await snap.ref.delete();

      return { success: true, message: 'Password reset successfully' };
    } catch (err) {
      console.error('❌ Password reset error:', err);
      // Wrap unknown errors so client gets a proper HttpsError
      if (err instanceof HttpsError) throw err;
      throw new HttpsError('internal', 'Failed to reset password');
    }
  }
);

// ──────────────────────────────────────────────────────────────────────────────
//  5. Periodic cleanup of stale codes
// ──────────────────────────────────────────────────────────────────────────────
exports.cleanupOldVerificationCodes = onSchedule(
  { schedule: 'every 15 minutes', region: 'us-central1' },
  async () => {
    const cutoff = new Date(Date.now() - 15 * 60 * 1000);
    const db     = admin.firestore();

    const verifications = await db.collection('verifications')
      .where('created_at', '<', cutoff).get();
    const resets = await db.collection('password_resets')
      .where('created_at', '<', cutoff).get();

    const batch = db.batch();
    [...verifications.docs, ...resets.docs].forEach((doc) => batch.delete(doc.ref));
    await batch.commit();

    console.log(`🧹 Cleaned ${verifications.size} verifications & ${resets.size} resets`);
  }
);

// ──────────────────────────────────────────────────────────────────────────────
