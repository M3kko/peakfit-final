// admin.js - Shared admin instance
const { initializeApp, getApps } = require('firebase-admin/app');

// Initialize admin only if no apps exist
let admin;
if (!getApps().length) {
  admin = initializeApp();
} else {
  admin = getApps()[0];
}

module.exports = require('firebase-admin');