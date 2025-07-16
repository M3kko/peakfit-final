const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { createClient } = require('@supabase/supabase-js');
const functions = require('firebase-functions');

// Initialize Firebase Admin
initializeApp();

// Initialize Supabase
let supabase = null;
try {
  // Get config values
  const config = functions.config();
  const supabaseUrl = config.supabase?.url;
  const supabaseServiceKey = config.supabase?.service_key;
  
  if (supabaseUrl && supabaseServiceKey) {
    supabase = createClient(supabaseUrl, supabaseServiceKey);
    console.log('Supabase initialized successfully');
  } else {
    console.log('Supabase config not found');
  }
} catch (error) {
  console.error('Error initializing Supabase:', error);
}

// Test function
exports.helloWorld = onRequest((request, response) => {
  response.send("Hello from Firebase v6 with Supabase!");
});

// Marketing consent sync
exports.syncMarketingConsent = onDocumentWritten({
  document: 'users/{userId}',
  region: 'us-central1',
}, async (event) => {
  // Get the data
  const newData = event.data?.after?.data();
  const previousData = event.data?.before?.data();
  const userId = event.params.userId;
  
  // Skip if no email or Supabase not configured
  if (!newData?.email || !supabase) {
    console.log('Skipping sync - no email or Supabase not configured');
    return null;
  }
  
  // Check if marketing consent changed
  if (newData.marketing_consent !== previousData?.marketing_consent) {
    console.log('Marketing consent changed to:', newData.marketing_consent);
    
    try {
      if (newData.marketing_consent === true) {
        // Add to Supabase marketing list
        const { data, error } = await supabase
          .from('marketing_subscribers')
          .upsert({
            email: newData.email,
            firebase_uid: userId,
            subscribed_at: new Date().toISOString(),
            status: 'active',
            source: 'peakfit_app'
          }, {
            onConflict: 'email'
          });
        
        if (error) {
          console.error('Supabase insert error:', error);
          return null;
        }
        
        console.log('Successfully added to marketing list:', newData.email);
        
      } else if (newData.marketing_consent === false) {
        // Update status to unsubscribed
        const { data, error } = await supabase
          .from('marketing_subscribers')
          .update({
            status: 'unsubscribed',
            unsubscribed_at: new Date().toISOString()
          })
          .eq('email', newData.email);
        
        if (error) {
          console.error('Supabase update error:', error);
          return null;
        }
        
        console.log('Successfully unsubscribed:', newData.email);
      }
    } catch (error) {
      console.error('Error syncing to Supabase:', error);
    }
  }
  
  return null;
});

// Log verification codes (for email verification feature)
exports.logVerificationCode = onDocumentWritten({
  document: 'verifications/{email}',
  region: 'us-central1',
}, async (event) => {
  const data = event.data?.after?.data();
  if (data) {
    console.log(`Verification code for ${data.email}: ${data.code}`);
  }
  return null;
});