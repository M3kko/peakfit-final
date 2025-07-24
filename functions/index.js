const { onCall, onRequest } = require('firebase-functions/v2/https');
const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
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
  // Escape HTML entities for security
  const escapeHtml = (str) => {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  };

  return `<!DOCTYPE html>
<html lang="en" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="x-apple-disable-message-reformatting">
  <meta name="format-detection" content="telephone=no, date=no, address=no, email=no">
  <meta name="color-scheme" content="light">
  <meta name="supported-color-schemes" content="light">
  <title>${escapeHtml(title)}</title>
  <!--[if gte mso 9]>
  <xml>
    <o:OfficeDocumentSettings>
      <o:AllowPNG/>
      <o:PixelsPerInch>96</o:PixelsPerInch>
    </o:OfficeDocumentSettings>
  </xml>
  <![endif]-->
  <!--[if mso]>
  <noscript>
    <xml>
      <o:OfficeDocumentSettings>
        <o:PixelsPerInch>96</o:PixelsPerInch>
      </o:OfficeDocumentSettings>
    </xml>
  </noscript>
  <![endif]-->
  <style type="text/css">
    /* Reset styles */
    body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
    table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
    img { -ms-interpolation-mode: bicubic; }

    /* Remove default styling */
    img { border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; }
    table { border-collapse: collapse !important; }
    body { height: 100% !important; margin: 0 !important; padding: 0 !important; width: 100% !important; }

    /* Mobile styles */
    @media screen and (max-width: 600px) {
      .mobile-hide { display: none !important; }
      .mobile-center { text-align: center !important; }
      .mobile-padding { padding: 20px !important; }
      table.responsive-table { width: 100% !important; }
      td.responsive-td { font-size: 16px !important; line-height: 24px !important; }
    }

    /* Dark mode support */
    @media (prefers-color-scheme: dark) {
      .dark-mode-bg { background-color: #1a1a1a !important; }
      .dark-mode-text { color: #ffffff !important; }
    }

    /* Outlook-specific styles */
    <!--[if mso]>
    table { border-collapse: collapse; border-spacing: 0; margin: 0; }
    div, td { font-family: Arial, sans-serif; }
    <![endif]-->
  </style>
</head>
<body style="margin: 0; padding: 0; word-spacing: normal; background-color: #f4f4f4;">
  <div role="article" aria-roledescription="email" lang="en" style="text-size-adjust: 100%; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%;">
    <!--[if mso | IE]>
    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #f4f4f4;">
    <tr>
    <td>
    <![endif]-->
    
    <table align="center" role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" style="margin: auto;" class="responsive-table">
      <tr>
        <td style="padding: 20px 0;">
          <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
            <!-- Preheader text for email clients -->
            <tr>
              <td>
                <div style="display: none; font-size: 1px; color: #f4f4f4; line-height: 1px; font-family: Arial, sans-serif; max-height: 0px; max-width: 0px; opacity: 0; overflow: hidden;">
                  Your PeakFit verification code: ${code}
                </div>
              </td>
            </tr>
            
            <!-- Header -->
            <tr>
              <td style="background-color: #000000; border-radius: 10px 10px 0 0; padding: 40px 20px; text-align: center;">
                <!--[if mso]>
                <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                <td style="text-align: center;">
                <![endif]-->
                <h1 style="margin: 0; font-family: Arial, Helvetica, sans-serif; font-size: 32px; font-weight: 300; letter-spacing: 2px; color: #D4AF37; line-height: 36px;">PEAKFIT</h1>
                ${subtitle ? `<p style="margin: 10px 0 0 0; font-family: Arial, Helvetica, sans-serif; font-size: 14px; color: #D4AF37; line-height: 20px;">${escapeHtml(subtitle)}</p>` : ''}
                <!--[if mso]>
                </td>
                </tr>
                </table>
                <![endif]-->
              </td>
            </tr>
            
            <!-- Body -->
            <tr>
              <td style="background-color: #ffffff; border-left: 1px solid #e0e0e0; border-right: 1px solid #e0e0e0; padding: 40px 20px;" class="mobile-padding">
                <!--[if mso]>
                <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                <td>
                <![endif]-->
                <h2 style="margin: 0 0 20px 0; font-family: Arial, Helvetica, sans-serif; font-size: 24px; font-weight: normal; color: #333333; line-height: 32px;" class="responsive-td">${escapeHtml(title)}</h2>
                <p style="margin: 0 0 30px 0; font-family: Arial, Helvetica, sans-serif; font-size: 16px; line-height: 24px; color: #666666;" class="responsive-td">${escapeHtml(content)}</p>
                
                <!-- Code Box -->
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center" style="margin: 0 auto;">
                  <tr>
                    <td style="background-color: #fafafa; border: 2px solid #D4AF37; border-radius: 8px; padding: 30px 40px; text-align: center;">
                      <p style="margin: 0; font-family: 'Courier New', Courier, monospace; font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #000000; line-height: 36px;">
                        ${escapeHtml(code)}
                      </p>
                    </td>
                  </tr>
                </table>
                
                <p style="margin: 30px 0 0 0; font-family: Arial, Helvetica, sans-serif; font-size: 14px; line-height: 20px; color: #999999; text-align: center;">This code will expire in 15 minutes.</p>
                
                <!-- Security notice for account deletion -->
                ${title === 'Confirm Account Deletion' ? `
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin-top: 30px;">
                  <tr>
                    <td style="background-color: #fff3cd; border: 1px solid #ffeeba; border-radius: 4px; padding: 15px;">
                      <p style="margin: 0; font-family: Arial, Helvetica, sans-serif; font-size: 14px; line-height: 20px; color: #856404;">
                        <strong>Warning:</strong> This action cannot be undone. All your data will be permanently deleted.
                      </p>
                    </td>
                  </tr>
                </table>
                ` : ''}
                <!--[if mso]>
                </td>
                </tr>
                </table>
                <![endif]-->
              </td>
            </tr>
            
            <!-- Footer -->
            <tr>
              <td style="background-color: #f8f8f8; border: 1px solid #e0e0e0; border-top: none; border-radius: 0 0 10px 10px; padding: 20px; text-align: center;">
                <!--[if mso]>
                <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                <td style="text-align: center;">
                <![endif]-->
                <p style="margin: 0 0 10px 0; font-family: Arial, Helvetica, sans-serif; font-size: 12px; line-height: 18px; color: #999999;">
                  © 2025 PeakFit. All rights reserved.
                </p>
                <p style="margin: 0; font-family: Arial, Helvetica, sans-serif; font-size: 12px; line-height: 18px; color: #999999;">
                  If you didn't request this email, please ignore it.
                </p>
                <p style="margin: 10px 0 0 0; font-family: Arial, Helvetica, sans-serif; font-size: 11px; line-height: 16px; color: #999999;">
                  <a href="mailto:support@peakfit.ai" style="color: #D4AF37; text-decoration: none;">Contact Support</a>
                </p>
                <!--[if mso]>
                </td>
                </tr>
                </table>
                <![endif]-->
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
    
    <!--[if mso | IE]>
    </td>
    </tr>
    </table>
    <![endif]-->
  </div>
</body>
</html>`;
}

// Helper function to create plain text email with better formatting
function createEmailText(title, content, code, isAccountDeletion = false) {
  const divider = '='.repeat(60);
  const codeDivider = '-'.repeat(20);
  
  let emailText = `PEAKFIT
${divider}

${title.toUpperCase()}

${content}

${codeDivider}
VERIFICATION CODE: ${code}
${codeDivider}

This code will expire in 15 minutes.

`;

  if (isAccountDeletion) {
    emailText += `
WARNING: This action cannot be undone. All your data will be permanently deleted.

`;
  }

  emailText += `${divider}
© 2025 PeakFit. All rights reserved.

If you didn't request this email, please ignore it.

Need help? Contact us at support@peakfit.ai
`;

  return emailText;
}

// ============================================
// HTTP FUNCTIONS
// ============================================

// Simple hello world endpoint for testing
exports.helloWorld = onRequest({ region: 'us-central1' }, (req, res) => {
  res.send('Hello from Firebase');
});

// ============================================
// FIRESTORE TRIGGERS
// ============================================

// Sync marketing consent to Supabase
exports.syncMarketingConsent = onDocumentWritten({
  document: 'users/{uid}',
  region: 'us-central1',
  secrets: [SUPABASE_URL, SUPABASE_SERVICE_KEY]
}, async (event) => {
  // Only process if we have Supabase credentials
  if (!SUPABASE_URL.value() || !SUPABASE_SERVICE_KEY.value()) {
    console.log('Supabase credentials not configured, skipping sync');
    return null;
  }

  const supabase = createClient(
    SUPABASE_URL.value(),
    SUPABASE_SERVICE_KEY.value()
  );
  
  const after = event.data?.after?.data();
  const before = event.data?.before?.data();
  
  // Handle user deletion
  if (!after && before) {
    // User document was deleted
    if (before.email) {
      try {
        // Delete from Supabase for GDPR compliance
        const { error } = await supabase
          .from('users_email')
          .delete()
          .eq('email', before.email.toLowerCase());
          
        if (error) {
          console.error('Failed to delete from Supabase on user deletion:', error);
        } else {
          console.log('User deleted from Supabase after Firestore deletion');
        }
      } catch (err) {
        console.error('Supabase deletion error:', err);
      }
    }
    return null;
  }
  
  // Skip if no email in the new data
  if (!after?.email) return null;
  
  // Check if email changed
  const emailChanged = before?.email && before.email !== after.email;
  const marketingConsentChanged = before?.marketing_consent !== after.marketing_consent;
  
  // Skip if nothing relevant changed
  if (!emailChanged && !marketingConsentChanged && before?.email === after.email) {
    return null;
  }
  
  try {
    // If email changed, handle the old email first
    if (emailChanged && before?.email) {
      console.log(`Email changed from ${before.email} to ${after.email}`);
      
      // Delete the old email from Supabase
      const { error: deleteError } = await supabase
        .from('users_email')
        .delete()
        .eq('email', before.email.toLowerCase());
        
      if (deleteError) {
        console.error('Failed to delete old email from Supabase:', deleteError);
      } else {
        console.log('Old email removed from Supabase:', before.email);
      }
    }
    
    // Now handle the current email (new or updated)
    const { data: existing, error: checkError } = await supabase
      .from('users_email')
      .select('id')
      .eq('email', after.email.trim().toLowerCase())
      .maybeSingle();

    if (checkError && checkError.code !== 'PGRST116') {
      console.error('Error checking existing email:', checkError);
    }

    const emailData = {
      firebase_uid: event.params.uid,
      marketing_consent: after.marketing_consent || false,
      marketing_consent_date: after.marketing_consent && after.marketing_consent_date 
        ? after.marketing_consent_date.toDate().toISOString() 
        : null,
      email_type: after.marketing_consent ? 'both' : 'user',
      status: 'active',
      email_verified: after.email_verified || false,
      updated_at: new Date().toISOString()
    };

    if (existing) {
      // Update existing entry
      const { error } = await supabase
        .from('users_email')
        .update(emailData)
        .eq('email', after.email.trim().toLowerCase());
      
      if (error) {
        console.error('Failed to update email in Supabase:', error);
      } else {
        console.log('Email updated in Supabase:', after.email);
      }
    } else {
      // Insert new entry
      const { error } = await supabase
        .from('users_email')
        .insert({
          email: after.email.trim().toLowerCase(),
          ...emailData,
          source: 'peakfit_app',
          created_at: new Date().toISOString()
        });
      
      if (error) {
        console.error('Failed to insert email in Supabase:', error);
      } else {
        console.log('Email inserted in Supabase:', after.email);
      }
    }
    
    console.log(`Marketing consent synced for ${after.email} (consent: ${after.marketing_consent})`);
  } catch (err) {
    console.error('Supabase sync error:', JSON.stringify(err));
  }
  
  return null;
});

// Send verification email when code is created
exports.onVerificationCodeCreated = onDocumentCreated({
  document: 'verifications/{email}',
  region: 'us-central1',
  secrets: [RESEND_API_KEY]
}, async (event) => {
  const data = event.data.data();
  if (!data) return null;

  console.log(`Sending verification code ${data.code} to ${data.email}`);

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
        'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click',
        'X-Priority': '3',
        'X-MSMail-Priority': 'Normal',
        'Importance': 'normal',
        'X-Mailer': 'PeakFit-Mailer/1.0',
        'MIME-Version': '1.0',
        'Content-Type': 'multipart/alternative; boundary="boundary-string"'
      },
      tags: [
        {
          name: 'category',
          value: 'verification'
        },
        {
          name: 'transactional',
          value: 'true'
        }
      ],
      replyTo: 'support@peakfit.ai'
    });

    if (error) {
      console.error('Failed to send verification email:', error);
      throw new Error(error.message);
    } else {
      console.log('Verification email sent successfully to', data.email, 'with ID:', result.id);
    }
  } catch (err) {
    console.error('Resend error:', err);
    throw err;
  }

  return null;
});

// Send password reset email when code is created
exports.onPasswordResetCodeCreated = onDocumentCreated({
  document: 'password_resets/{email}',
  region: 'us-central1',
  secrets: [RESEND_API_KEY]
}, async (event) => {
  const data = event.data.data();
  if (!data) return null;

  console.log(`Sending password reset code ${data.code} to ${data.email}`);

  const resend = new Resend(RESEND_API_KEY.value());

  try {
    const title = 'Reset Your Password';
    const subtitle = 'Password Recovery';
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
        'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click',
        'X-Priority': '1',
        'X-MSMail-Priority': 'High',
        'Importance': 'high',
        'X-Mailer': 'PeakFit-Mailer/1.0',
        'MIME-Version': '1.0',
        'Content-Type': 'multipart/alternative; boundary="boundary-string"'
      },
      tags: [
        {
          name: 'category',
          value: 'password-reset'
        },
        {
          name: 'transactional',
          value: 'true'
        },
        {
          name: 'security',
          value: 'true'
        }
      ],
      replyTo: 'support@peakfit.ai'
    });

    if (error) {
      console.error('Failed to send password reset email:', error);
      throw new Error(error.message);
    } else {
      console.log('Password reset email sent successfully to', data.email, 'with ID:', result.id);
    }
  } catch (err) {
    console.error('Resend error:', err);
    throw err;
  }

  return null;
});

// Send account deletion email when request is created
exports.onDeleteRequestCreated = onDocumentCreated({
  document: 'delete_requests/{uid}',
  region: 'us-central1',
  secrets: [RESEND_API_KEY]
}, async (event) => {
  const data = event.data.data();
  if (!data) return null;

  console.log(`Sending delete account code ${data.code} to ${data.email}`);

  const resend = new Resend(RESEND_API_KEY.value());

  try {
    const title = 'Confirm Account Deletion';
    const subtitle = 'Important Security Verification';
    const content = 'You have requested to permanently delete your PeakFit account. This action cannot be undone. All your data, including workouts, achievements, and progress will be permanently removed. Please use the verification code below to confirm this action.';
    
    // Generate a unique ID based on UID and timestamp to prevent duplicates
    const timestamp = data.created_at ? data.created_at._seconds * 1000 : Date.now();
    
    const { data: result, error } = await resend.emails.send({
      from: 'PeakFit <hello@peakfit.ai>',
      to: [data.email],
      subject: 'PeakFit Account Deletion Verification',
      text: createEmailText(title, content, data.code, true),
      html: createEmailHTML(title, subtitle, content, data.code),
      headers: {
        'X-Entity-Ref-ID': `account-deletion-${event.params.uid}-${timestamp}`,
        'List-Unsubscribe': '<mailto:unsubscribe@peakfit.ai>',
        'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click',
        'X-Priority': '1',
        'X-MSMail-Priority': 'High',
        'Importance': 'high',
        'X-Mailer': 'PeakFit-Mailer/1.0',
        'MIME-Version': '1.0',
        'Content-Type': 'multipart/alternative; boundary="boundary-string"',
        'X-Account-Deletion': 'true'
      },
      tags: [
        {
          name: 'category',
          value: 'account-deletion'
        },
        {
          name: 'security',
          value: 'high'
        },
        {
          name: 'transactional',
          value: 'true'
        },
        {
          name: 'critical',
          value: 'true'
        }
      ],
      replyTo: 'support@peakfit.ai'
    });

    if (error) {
      console.error('Failed to send account deletion email:', error);
      throw new Error(error.message);
    } else {
      console.log('Account deletion email sent successfully to', data.email, 'with ID:', result.id);
    }
  } catch (err) {
    console.error('Resend error:', err);
    throw err;
  }

  return null;
});

// Send email change verification when request is created
exports.onEmailChangeCodeCreated = onDocumentCreated({
  document: 'email_changes/{uid}',
  region: 'us-central1',
  secrets: [RESEND_API_KEY]
}, async (event) => {
  const data = event.data.data();
  if (!data) return null;

  console.log(`Sending email change code ${data.code} to ${data.newEmail}`);

  const resend = new Resend(RESEND_API_KEY.value());

  try {
    const title = 'Verify Your New Email';
    const subtitle = 'Email Change Request';
    const content = 'You have requested to change your PeakFit email address. Please use the verification code below to confirm your new email address.';
    
    // Generate a unique ID based on UID and timestamp to prevent duplicates
    const timestamp = data.created_at ? data.created_at._seconds * 1000 : Date.now();
    
    const { data: result, error } = await resend.emails.send({
      from: 'PeakFit <hello@peakfit.ai>',
      to: [data.newEmail],
      subject: 'Verify Your New PeakFit Email',
      text: createEmailText(title, content, data.code),
      html: createEmailHTML(title, subtitle, content, data.code),
      headers: {
        'X-Entity-Ref-ID': `email-change-${event.params.uid}-${timestamp}`,
        'List-Unsubscribe': '<mailto:unsubscribe@peakfit.ai>',
        'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click',
        'X-Priority': '2',
        'X-MSMail-Priority': 'High',
        'Importance': 'high',
        'X-Mailer': 'PeakFit-Mailer/1.0',
        'MIME-Version': '1.0',
        'Content-Type': 'multipart/alternative; boundary="boundary-string"',
        'X-Previous-Email': data.currentEmail || 'unknown'
      },
      tags: [
        {
          name: 'category',
          value: 'email-change'
        },
        {
          name: 'transactional',
          value: 'true'
        },
        {
          name: 'security',
          value: 'true'
        }
      ],
      replyTo: 'support@peakfit.ai'
    });

    if (error) {
      console.error('Failed to send email change verification:', error);
      throw new Error(error.message);
    } else {
      console.log('Email change verification sent successfully to', data.newEmail, 'with ID:', result.id);
    }
  } catch (err) {
    console.error('Resend error:', err);
    throw err;
  }

  return null;
});

// ============================================
// CALLABLE FUNCTIONS
// ============================================

// Reset password with verification code
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

// Delete account with verification code - COMPREHENSIVE DELETION
exports.deleteAccountWithCode = onCall({ 
  region: 'us-central1',
  cors: true 
}, async (request) => {
  if (!request.auth) {
    throw new Error('User must be authenticated');
  }

  const { code } = request.data;
  const uid = request.auth.uid;

  if (!code) {
    throw new Error('Verification code is required');
  }

  try {
    // Get the delete request document
    const deleteRequestDoc = await db.collection('delete_requests').doc(uid).get();

    if (!deleteRequestDoc.exists) {
      throw new Error('No deletion request found');
    }

    const deleteRequest = deleteRequestDoc.data();

    // Check if code matches
    if (deleteRequest.code !== code.trim()) {
      throw new Error('Invalid verification code');
    }

    // Check if code is expired (15 minutes)
    const createdAt = deleteRequest.created_at.toDate();
    const now = new Date();
    const fifteenMinutes = 15 * 60 * 1000;
    
    if (now - createdAt > fifteenMinutes) {
      throw new Error('Verification code has expired');
    }

    // Get user document first for cleanup
    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.exists ? userDoc.data() : null;

    // Proceed with account deletion
    const batch = db.batch();

    // Delete user document
    batch.delete(db.collection('users').doc(uid));

    // Delete username document if exists
    if (userData && userData.username) {
      const username = userData.username.toLowerCase();
      batch.delete(db.collection('usernames').doc(username));
    }

    // Delete all user subcollections - expanded list
    const subcollections = [
      'achievements', 
      'workouts', 
      'programs', 
      'exercises',
      'routines',
      'progress',
      'stats',
      'preferences',
      'notifications',
      'messages'
    ];
    
    for (const subcollection of subcollections) {
      try {
        const snapshot = await db.collection('users').doc(uid).collection(subcollection).get();
        console.log(`Deleting ${snapshot.size} documents from ${subcollection} subcollection`);
        snapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
      } catch (e) {
        console.log(`Subcollection ${subcollection} may not exist, skipping`);
      }
    }

    // Delete the delete request document
    batch.delete(db.collection('delete_requests').doc(uid));

    // Delete any verification documents
    if (userData && userData.email) {
      const email = userData.email.toLowerCase();
      
      // Delete from verifications collection
      const verificationDoc = await db.collection('verifications').doc(email).get();
      if (verificationDoc.exists) {
        batch.delete(db.collection('verifications').doc(email));
      }
      
      // Delete from password_resets collection
      const passwordResetDoc = await db.collection('password_resets').doc(email).get();
      if (passwordResetDoc.exists) {
        batch.delete(db.collection('password_resets').doc(email));
      }
      
      // Delete from email_changes collection
      const emailChangeDoc = await db.collection('email_changes').doc(uid).get();
      if (emailChangeDoc.exists) {
        batch.delete(db.collection('email_changes').doc(uid));
      }
      
      // Delete from user_emails collection
      const userEmailDoc = await db.collection('user_emails').doc(email).get();
      if (userEmailDoc.exists) {
        batch.delete(db.collection('user_emails').doc(email));
      }
    }

    // Commit all deletions
    await batch.commit();
    console.log('Firestore deletions completed successfully');

    // Delete profile images from storage
    if (userData && (userData.profileImageUrl || true)) { // Always try to delete storage
      try {
        const storage = admin.storage();
        const bucket = storage.bucket();
        
        // Delete all files in the user's profile_images folder
        const folderPath = `profile_images/${uid}/`;
        const [files] = await bucket.getFiles({ prefix: folderPath });
        
        console.log(`Found ${files.length} files to delete in storage`);
        
        // Delete all files in parallel
        await Promise.all(files.map(file => {
          console.log(`Deleting file: ${file.name}`);
          return file.delete();
        }));
        
        console.log('Storage deletions completed successfully');
      } catch (storageError) {
        console.error('Failed to delete storage files:', storageError);
        // Don't throw - continue with deletion even if storage cleanup fails
      }
    }

    // Delete any other storage references (e.g., workout videos, progress photos)
    try {
      const storage = admin.storage();
      const bucket = storage.bucket();
      
      // Check for other potential storage locations
      const otherFolders = [`workouts/${uid}/`, `progress/${uid}/`, `videos/${uid}/`];
      
      for (const folder of otherFolders) {
        try {
          const [files] = await bucket.getFiles({ prefix: folder });
          if (files.length > 0) {
            console.log(`Deleting ${files.length} files from ${folder}`);
            await Promise.all(files.map(file => file.delete()));
          }
        } catch (e) {
          console.log(`No files found in ${folder}`);
        }
      }
    } catch (e) {
      console.error('Error cleaning up additional storage:', e);
    }

    // GDPR Compliance: Completely delete user data from Supabase
    if (userData && userData.email && SUPABASE_URL.value() && SUPABASE_SERVICE_KEY.value()) {
      try {
        const supabase = createClient(
          SUPABASE_URL.value(),
          SUPABASE_SERVICE_KEY.value()
        );
        
        // Delete the user record entirely from Supabase for GDPR compliance
        const { error } = await supabase
          .from('users_email')
          .delete()
          .eq('email', userData.email.toLowerCase());
          
        if (error) {
          console.error('Failed to delete from Supabase:', error);
        } else {
          console.log('User data deleted from Supabase for GDPR compliance');
        }
      } catch (supabaseError) {
        console.error('Failed to delete from Supabase:', supabaseError);
        // Don't throw - continue with deletion even if Supabase deletion fails
      }
    }

    // Delete the user from Firebase Auth - do this last
    await auth.deleteUser(uid);
    console.log('Firebase Auth user deleted successfully');

    console.log(`Successfully deleted all data for user: ${uid}`);
    return { success: true, message: 'Account successfully deleted' };

  } catch (error) {
    console.error('Account deletion error:', error);
    throw new Error(error.message || 'Failed to delete account');
  }
});

// Change email with verification code
exports.changeEmailWithCode = onCall({ 
  region: 'us-central1',
  cors: true,
  secrets: [SUPABASE_URL, SUPABASE_SERVICE_KEY]
}, async (request) => {
  if (!request.auth) {
    throw new Error('User must be authenticated');
  }

  const { code } = request.data;
  const uid = request.auth.uid;

  if (!code) {
    throw new Error('Verification code is required');
  }

  try {
    // Get the email change request document
    const emailChangeDoc = await db.collection('email_changes').doc(uid).get();

    if (!emailChangeDoc.exists) {
      throw new Error('No email change request found');
    }

    const emailChangeData = emailChangeDoc.data();

    // Check if code matches
    if (emailChangeData.code !== code.trim()) {
      throw new Error('Invalid verification code');
    }

    // Check if code is expired (15 minutes)
    const createdAt = emailChangeData.created_at.toDate();
    const now = new Date();
    const fifteenMinutes = 15 * 60 * 1000;
    
    if (now - createdAt > fifteenMinutes) {
      throw new Error('Verification code has expired');
    }

    const newEmail = emailChangeData.newEmail;
    const oldEmail = emailChangeData.currentEmail;

    // Update Firebase Auth email
    await auth.updateUser(uid, { email: newEmail });

    // Update Firestore user document
    await db.collection('users').doc(uid).update({
      email: newEmail,
      email_verified: true,
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update user_emails collection
    if (oldEmail) {
      // Delete old email entry
      const oldEmailDoc = await db.collection('user_emails').doc(oldEmail.toLowerCase()).get();
      if (oldEmailDoc.exists) {
        await oldEmailDoc.ref.delete();
      }
    }

    // Add new email entry
    await db.collection('user_emails').doc(newEmail.toLowerCase()).set({
      uid: uid,
      email: newEmail,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update email in Supabase - FIXED: Now properly syncing
    if (SUPABASE_URL.value() && SUPABASE_SERVICE_KEY.value()) {
      try {
        const supabase = createClient(
          SUPABASE_URL.value(),
          SUPABASE_SERVICE_KEY.value()
        );

        // Get the user's current marketing consent from Firestore
        const userDoc = await db.collection('users').doc(uid).get();
        const userData = userDoc.data();
        const marketingConsent = userData?.marketing_consent || false;
        const marketingConsentDate = userData?.marketing_consent_date;

        if (oldEmail) {
          // Delete old email entry from Supabase
          const { error: deleteError } = await supabase
            .from('users_email')
            .delete()
            .eq('email', oldEmail.toLowerCase());

          if (deleteError) {
            console.error('Failed to delete old email from Supabase:', deleteError);
          } else {
            console.log('Old email deleted from Supabase:', oldEmail);
          }
        }

        // Check if new email already exists in Supabase
        const { data: existingNew, error: checkError } = await supabase
          .from('users_email')
          .select('id')
          .eq('email', newEmail.toLowerCase())
          .maybeSingle(); // Use maybeSingle instead of single to avoid errors

        if (checkError && checkError.code !== 'PGRST116') {
          console.error('Error checking existing email:', checkError);
        }

        if (existingNew) {
          // Update existing entry
          const { error: updateError } = await supabase
            .from('users_email')
            .update({
              firebase_uid: uid,
              marketing_consent: marketingConsent,
              marketing_consent_date: marketingConsent && marketingConsentDate 
                ? marketingConsentDate.toDate().toISOString() 
                : null,
              email_type: marketingConsent ? 'both' : 'user',
              status: 'active',
              email_verified: true,
              updated_at: new Date().toISOString()
            })
            .eq('email', newEmail.toLowerCase());
          
          if (updateError) {
            console.error('Failed to update email in Supabase:', updateError);
          } else {
            console.log('Email updated in Supabase successfully');
          }
        } else {
          // Create new entry
          const { error: insertError } = await supabase
            .from('users_email')
            .insert({
              email: newEmail.toLowerCase(),
              firebase_uid: uid,
              marketing_consent: marketingConsent,
              marketing_consent_date: marketingConsent && marketingConsentDate 
                ? marketingConsentDate.toDate().toISOString() 
                : null,
              email_type: marketingConsent ? 'both' : 'user',
              status: 'active',
              source: 'peakfit_app',
              email_verified: true,
              created_at: new Date().toISOString()
            });
          
          if (insertError) {
            console.error('Failed to insert new email in Supabase:', insertError);
          } else {
            console.log('New email inserted in Supabase successfully');
          }
        }

        // Force sync by triggering the syncMarketingConsent function
        console.log(`Email successfully synced to Supabase: ${newEmail}`);
      } catch (supabaseError) {
        console.error('Failed to update email in Supabase:', supabaseError);
        // Don't throw - email change in Firebase was successful
        // We'll log the error but continue with the success response
      }
    } else {
      console.log('Supabase credentials not configured, skipping Supabase sync');
    }

    // Delete the email change request
    await emailChangeDoc.ref.delete();

    console.log(`Email successfully changed for user: ${uid} from ${oldEmail} to ${newEmail}`);
    return { success: true, newEmail: newEmail };

  } catch (error) {
    console.error('Email change error:', error);
    throw new Error(error.message || 'Failed to change email');
  }
});

// ============================================
// SCHEDULED FUNCTIONS
// ============================================

// Clean up expired verification codes
exports.cleanupExpiredCodes = onSchedule({
  schedule: 'every 15 minutes',
  region: 'us-central1'
}, async (event) => {
  const expiry = new Date(Date.now() - 15 * 60 * 1000);
  
  const collections = ['verifications', 'password_resets', 'delete_requests', 'email_changes'];
  let totalDeleted = 0;

  for (const collection of collections) {
    try {
      const snapshot = await db.collection(collection)
        .where('created_at', '<', expiry)
        .get();
      
      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      
      if (snapshot.size > 0) {
        await batch.commit();
        totalDeleted += snapshot.size;
        console.log(`Deleted ${snapshot.size} expired documents from ${collection}`);
      }
    } catch (error) {
      console.error(`Error cleaning up ${collection}:`, error);
    }
  }
  
  console.log(`Total cleanup: ${totalDeleted} expired codes deleted`);
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