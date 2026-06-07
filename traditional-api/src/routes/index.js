const express = require('express');
const router  = express.Router();

const authController        = require('../controllers/auth.controller');
const accountController     = require('../controllers/account.controller');
const transactionController = require('../controllers/transaction.controller');
const { protect }           = require('../middleware/auth');

// ============================================================
// AUTH ROUTES
// No protection needed — these are the login/register endpoints
// ============================================================
router.post('/auth/register', authController.register);
router.post('/auth/login',    authController.login);
router.get('/auth/me',        protect, authController.getMe);

// ============================================================
// ACCOUNT ROUTES
// All protected — must be logged in
// ============================================================
router.post('/accounts',                          protect, accountController.createAccount);
router.get('/accounts',                           protect, accountController.getMyAccounts);
router.get('/accounts/:id',                       protect, accountController.getAccount);
router.get('/accounts/:id/balance',               protect, accountController.getBalance);
router.get('/accounts/:id/transactions',          protect, accountController.getAccountTransactions);
router.patch('/accounts/:id/status',              protect, accountController.updateStatus);

// ============================================================
// TRANSACTION ROUTES
// All protected — must be logged in
// ============================================================
router.post('/transactions/deposit',              protect, transactionController.deposit);
router.post('/transactions/withdraw',             protect, transactionController.withdraw);
router.post('/transactions/transfer',             protect, transactionController.transfer);
router.get('/transactions/:id',                   protect, transactionController.getTransaction);
router.post('/transactions/:id/reverse',          protect, transactionController.reverse);

// ============================================================
// HEALTH CHECK
// No protection — used to verify server is running
// ============================================================
router.get('/health', (req, res) => {
  res.json({
    success:   true,
    message:   'Core Banking API is running',
    timestamp: new Date().toISOString(),
    version:   '1.0.0',
    system:    'traditional',
  });
});

module.exports = router;