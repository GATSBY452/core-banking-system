require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const routes  = require('./src/routes');

const app  = express();
const PORT = process.env.PORT || 3000;

// ============================================================
// MIDDLEWARE
// ============================================================

// Allow requests from iOS app and browser
app.use(cors());

// Parse incoming JSON bodies
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Log every request to the console
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// ============================================================
// ROUTES
// All routes are prefixed with /api/v1
// ============================================================
app.use('/api/v1', routes);

// 404 handler — route not found
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.path} not found`,
  });
});

// Global error handler — catches unexpected errors
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
  });
});

// ============================================================
// START SERVER
// ============================================================
app.listen(PORT, () => {
  console.log('');
  console.log('🏦 ================================');
  console.log(`🏦  Core Banking API (Traditional)`);
  console.log(`🏦  Running on port ${PORT}`);
  console.log(`🏦  http://localhost:${PORT}/api/v1`);
  console.log('🏦 ================================');
  console.log('');
});

module.exports = app;