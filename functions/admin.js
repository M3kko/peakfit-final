// admin.js - Shared admin instance
const admin = require('firebase-admin');

// Initialize admin only once
if (!admin.apps.length) {
  admin.initializeApp();
}

module.exports = admin;