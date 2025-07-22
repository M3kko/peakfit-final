const { onCall, onRequest } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const { createClient } = require('@supabase/supabase-js');
const { Resend } = require('resend');

// Import admin from admin.js (which handles initialization)
const admin = require('./admin');

// Import exercise database
const ExerciseDatabase = require('./exercises_crud');

// Get auth and firestore from the already initialized admin
const auth = admin.auth();
const db = admin.firestore();

// Define secrets
const SUPABASE_URL = defineSecret('SUPABASE_URL');
const SUPABASE_SERVICE_KEY = defineSecret('SUPABASE_SERVICE_KEY');
const RESEND_API_KEY = defineSecret('RESEND_API_KEY');

// Helper function to create email-compliant HTML
function createEmailHTML(title, subtitle, content, code) {
  return `<!DOCTYPE html>
<html lang="en" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="x-apple-disable-message-reformatting">
  <title>${title}</title>
  <!--[if mso]>
  <xml>
    <o:OfficeDocumentSettings>
      <o:AllowPNG/>
      <o:PixelsPerInch>96</o:PixelsPerInch>
    </o:OfficeDocumentSettings>
  </xml>
  <![endif]-->
  <style type="text/css">
    /* Client-specific Styles */
    #outlook a { padding: 0; }
    body { margin: 0; padding: 0; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
    table, td { border-collapse: collapse; mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
    img { border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; -ms-interpolation-mode: bicubic; }
    p { display: block; margin: 13px 0; }
    
    /* General Styles */
    @media only screen and (min-width:480px) {
      .mj-column-per-100 { width: 100% !important; max-width: 100%; }
    }
    
    @media only screen and (max-width:480px) {
      table.full-width-mobile { width: 100% !important; }
      td.full-width-mobile { width: auto !important; }
    }
  </style>
</head>
<body style="margin: 0; padding: 0; background-color: #f4f4f4;">
  <div style="background-color: #f4f4f4;">
    <!--[if mso | IE]>
    <table align="center" border="0" cellpadding="0" cellspacing="0" style="width:600px;" width="600">
      <tr>
        <td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;">
    <![endif]-->
    
    <div style="margin: 0 auto; max-width: 600px;">
      <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="width: 100%;">
        <tbody>
          <tr>
            <td style="direction: ltr; font-size: 0px; padding: 20px 0; text-align: center;">
              <!--[if mso | IE]>
              <table role="presentation" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="vertical-align:top;width:600px;">
              <![endif]-->
              
              <div class="mj-column-per-100 outlook-group-fix" style="font-size: 0px; text-align: left; direction: ltr; display: inline-block; vertical-align: top; width: 100%;">
                <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                  <tbody>
                    <tr>
                      <td style="vertical-align: top; padding: 0;">
                        <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                          <!-- Header -->
                          <tr>
                            <td align="center" style="font-size: 0px; padding: 0; word-break: break-word;">
                              <div style="background: #000000; background: linear-gradient(135deg, #000000 0%, #1a1a1a 100%); padding: 40px 20px; text-align: center; border-radius: 10px 10px 0 0;">
                                <h1 style="margin: 0; font-family: Arial, sans-serif; font-size: 32px; font-weight: 300; letter-spacing: 2px; color: #D4AF37;">PEAKFIT</h1>
                                ${subtitle ? `<p style="margin: 10px 0 0 0; font-family: Arial, sans-serif; font-size: 14px; color: #D4AF37; opacity: 0.8;">${subtitle}</p>` : ''}
                              </div>
                            </td>
                          </tr>
                          
                          <!-- Body -->
                          <tr>
                            <td align="center" style="font-size: 0px; padding: 0; word-break: break-word;">
                              <div style="background: #ffffff; padding: 40px 20px; border: 1px solid #e0e0e0; border-top: none; border-radius: 0 0 10px 10px;">
                                <h2 style="margin: 0 0 20px 0; font-family: Arial, sans-serif; font-size: 24px; font-weight: normal; color: #333333;">${title}</h2>
                                <p style="margin: 0 0 20px 0; font-family: Arial, sans-serif; font-size: 16px; line-height: 1.6; color: #666666;">${content}</p>
                                
                                <!-- Code Box -->
                                <table border="0" cellpadding="0" cellspacing="0" role="presentation" style="margin: 30px auto;">
                                  <tr>
                                    <td style="background: #fafafa; border: 2px solid #D4AF37; border-radius: 8px; padding: 30px 40px; text-align: center;">
                                      <div style="font-family: 'Courier New', monospace; font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #000000;">${code}</div>
                                    </td>
                                  </tr>
                                </table>
                                
                                <p style="margin: 20px 0 0 0; font-family: Arial, sans-serif; font-size: 14px; line-height: 1.6; color: #999999;">This code will expire in 15 minutes.</p>
                              </div>
                            </td>
                          </tr>
                          
                          <!-- Footer -->
                          <tr>
                            <td align="center" style="font-size: 0px; padding: 20px 0 0 0; word-break: break-word;">
                              <p style="margin: 0; font-family: Arial, sans-serif; font-size: 12px; line-height: 1.6; color: #999999;">
                                © 2024 PeakFit. All rights reserved.<br>
                                If you didn't request this email, please ignore it.
                              </p>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              
              <!--[if mso | IE]>
                  </td>
                </tr>
              </table>
              <![endif]-->
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    
    <!--[if mso | IE]>
        </td>
      </tr>
    </table>
    <![endif]-->
  </div>
</body>
</html>`;
}

// Helper function to create plain text email
function createEmailText(title, content, code) {
  return `PEAKFIT

${title}

${content}

Your code is: ${code}

This code will expire in 15 minutes.

---
© 2024 PeakFit. All rights reserved.
If you didn't request this email, please ignore it.`;
}

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
    const title = 'Verify Your Email';
    const subtitle = 'Elite Fitness Awaits';
    const content = 'Thank you for joining PeakFit! Please use the verification code below to confirm your email address and unlock your personalized fitness journey.';
    
    const { data: result, error } = await resend.emails.send({
      from: 'PeakFit <hello@peakfit.ai>',
      to: [data.email],
      subject: 'Your PeakFit Verification Code',
      text: createEmailText(title, content, data.code),
      html: createEmailHTML(title, subtitle, content, data.code),
      headers: {
        'X-Entity-Ref-ID': `verification-${data.email}-${Date.now()}`,
        'List-Unsubscribe': '<mailto:unsubscribe@peakfit.ai>',
      },
      tags: [
        {
          name: 'category',
          value: 'verification'
        }
      ]
    });

    if (error) {
      console.error('Failed to send verification email:', error);
    } else {
      console.log('Verification email sent successfully to', data.email, 'with ID:', result.id);
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
    const title = 'Reset Your Password';
    const subtitle = null;
    const content = 'We received a request to reset your PeakFit password. Use the code below to set a new password and get back to your fitness journey.';
    
    const { data: result, error } = await resend.emails.send({
      from: 'PeakFit <hello@peakfit.ai>',
      to: [data.email],
      subject: 'Reset Your PeakFit Password',
      text: createEmailText(title, content, data.code),
      html: createEmailHTML(title, subtitle, content, data.code),
      headers: {
        'X-Entity-Ref-ID': `password-reset-${data.email}-${Date.now()}`,
        'List-Unsubscribe': '<mailto:unsubscribe@peakfit.ai>',
      },
      tags: [
        {
          name: 'category',
          value: 'password-reset'
        }
      ]
    });

    if (error) {
      console.error('Failed to send password reset email:', error);
    } else {
      console.log('Password reset email sent successfully to', data.email, 'with ID:', result.id);
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

// ============================================
// EXERCISE DATABASE FUNCTIONS
// ============================================

// Get all exercises
exports.getAllExercises = onCall({ 
  region: 'us-central1',
  cors: true 
}, async (request) => {
  if (!request.auth) {
    throw new Error('User must be authenticated');
  }
  
  const exerciseDB = new ExerciseDatabase();
  try {
    const includeVideos = request.data.includeVideos || false;
    const exercises = await exerciseDB.getAllExercises(includeVideos);
    return { exercises };
  } catch (error) {
    console.error('Error getting exercises:', error);
    throw new Error(error.message);
  }
});

// Get exercise by ID
exports.getExercise = onCall({ 
  region: 'us-central1',
  cors: true 
}, async (request) => {
  if (!request.auth) {
    throw new Error('User must be authenticated');
  }
  
  const { exerciseId } = request.data;
  if (!exerciseId) {
    throw new Error('Exercise ID is required');
  }
  
  const exerciseDB = new ExerciseDatabase();
  try {
    const exercise = await exerciseDB.getExercise(exerciseId);
    return { exercise };
  } catch (error) {
    console.error('Error getting exercise:', error);
    throw new Error(error.message);
  }
});

// Get exercises by equipment
exports.getExercisesByEquipment = onCall({ 
  region: 'us-central1',
  cors: true 
}, async (request) => {
  if (!request.auth) {
    throw new Error('User must be authenticated');
  }
  
  const { equipment, includeVideos } = request.data;
  if (!equipment || !Array.isArray(equipment)) {
    throw new Error('Equipment array is required');
  }
  
  const exerciseDB = new ExerciseDatabase();
  try {
    const exercises = await exerciseDB.getExercisesByEquipment(equipment, includeVideos || false);
    return { exercises };
  } catch (error) {
    console.error('Error getting exercises by equipment:', error);
    throw new Error(error.message);
  }
});

// Admin function to create exercise
exports.createExercise = onCall({ 
  region: 'us-central1',
  cors: true 
}, async (request) => {
  if (!request.auth) {
    throw new Error('User must be authenticated');
  }
  
  // Optional: Check for admin role
  // const isAdmin = request.auth.token.admin === true;
  // if (!isAdmin) {
  //   throw new Error('Admin access required');
  // }
  
  const exerciseDB = new ExerciseDatabase();
  try {
    const result = await exerciseDB.createExercise(request.data);
    return { exercise: result };
  } catch (error) {
    console.error('Error creating exercise:', error);
    throw new Error(error.message);
  }
});

// Admin function to update exercise
exports.updateExercise = onCall({ 
  region: 'us-central1',
  cors: true 
}, async (request) => {
  if (!request.auth) {
    throw new Error('User must be authenticated');
  }
  
  // Optional: Check for admin role
  // const isAdmin = request.auth.token.admin === true;
  // if (!isAdmin) {
  //   throw new Error('Admin access required');
  // }
  
  const { exerciseId, updates } = request.data;
  if (!exerciseId) {
    throw new Error('Exercise ID is required');
  }
  
  const exerciseDB = new ExerciseDatabase();
  try {
    const result = await exerciseDB.updateExercise(exerciseId, updates);
    return { exercise: result };
  } catch (error) {
    console.error('Error updating exercise:', error);
    throw new Error(error.message);
  }
});

// Admin function to delete exercise (soft delete)
exports.deleteExercise = onCall({ 
  region: 'us-central1',
  cors: true 
}, async (request) => {
  if (!request.auth) {
    throw new Error('User must be authenticated');
  }
  
  // Optional: Check for admin role
  // const isAdmin = request.auth.token.admin === true;
  // if (!isAdmin) {
  //   throw new Error('Admin access required');
  // }
  
  const { exerciseId } = request.data;
  if (!exerciseId) {
    throw new Error('Exercise ID is required');
  }
  
  const exerciseDB = new ExerciseDatabase();
  try {
    const result = await exerciseDB.deleteExercise(exerciseId);
    return result;
  } catch (error) {
    console.error('Error deleting exercise:', error);
    throw new Error(error.message);
  }
});