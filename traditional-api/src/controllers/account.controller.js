const accountModel = require('../models/account');
const { getTransactionHistory } = require('../engines/ledger');

/**
 * POST /api/v1/accounts
 *
 * Create an additional account for the logged in customer.
 * They already have a savings account from registration.
 * This is for when they want a current account or wallet too.
 */
const createAccount = async (req, res) => {
  try {
    const { accountType, accountName, currency } = req.body;

    // Only these types are allowed
    const validTypes = ['savings', 'current', 'wallet'];
    if (!validTypes.includes(accountType)) {
      return res.status(400).json({
        success: false,
        message: `Invalid account type. Must be one of: ${validTypes.join(', ')}`,
      });
    }

    const account = await accountModel.createAccount({
      customerId:  req.customer.id,
      accountType,
      accountName: accountName ||
        `${req.customer.first_name} ${req.customer.last_name} - ${accountType}`,
      currency:    currency || 'USD',
    });

    return res.status(201).json({
      success: true,
      message: 'Account created successfully.',
      data: {
        account: { ...account, balance: 0 }
      },
    });

  } catch (err) {
    console.error('Create account error:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to create account.',
    });
  }
};

/**
 * GET /api/v1/accounts
 *
 * Get all accounts for the logged in customer.
 * Each account includes its live balance.
 * This is the home screen of the banking app.
 */
const getMyAccounts = async (req, res) => {
  try {
    const accounts = await accountModel.getCustomerAccounts(req.customer.id);

    return res.json({
      success: true,
      data: {
        accounts,
        count: accounts.length,
      },
    });

  } catch (err) {
    console.error('Get accounts error:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch accounts.',
    });
  }
};

/**
 * GET /api/v1/accounts/:id
 *
 * Get a single account with its live balance.
 * Security: only returns the account if it belongs
 * to the logged in customer.
 */
const getAccount = async (req, res) => {
  try {
    // Pass both accountId AND customerId
    // Model will only return account if both match
    const account = await accountModel.getAccountById(
      req.params.id,
      req.customer.id
    );

    if (!account) {
      return res.status(404).json({
        success: false,
        message: 'Account not found.',
      });
    }

    return res.json({
      success: true,
      data: { account },
    });

  } catch (err) {
    console.error('Get account error:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch account.',
    });
  }
};

/**
 * GET /api/v1/accounts/:id/balance
 *
 * Get just the balance for quick checks.
 * Useful for the iOS app to refresh balance
 * without loading all account details.
 */
const getBalance = async (req, res) => {
  try {
    const account = await accountModel.getAccountById(
      req.params.id,
      req.customer.id
    );

    if (!account) {
      return res.status(404).json({
        success: false,
        message: 'Account not found.',
      });
    }

    return res.json({
      success: true,
      data: {
        accountId:     account.id,
        accountNumber: account.account_number,
        balance:       parseFloat(account.balance),
        currency:      account.currency,
      },
    });

  } catch (err) {
    console.error('Get balance error:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch balance.',
    });
  }
};

/**
 * GET /api/v1/accounts/:id/transactions
 *
 * Transaction history for an account.
 * This is what the app shows when you tap on an account.
 * Supports pagination via limit and offset query params.
 *
 * Example: /accounts/:id/transactions?limit=20&offset=0
 */
const getAccountTransactions = async (req, res) => {
  try {
    // First verify this account belongs to the customer
    const account = await accountModel.getAccountById(
      req.params.id,
      req.customer.id
    );

    if (!account) {
      return res.status(404).json({
        success: false,
        message: 'Account not found.',
      });
    }

    // Parse pagination params from URL
    // Default: 20 transactions per page starting from 0
    const limit  = parseInt(req.query.limit)  || 20;
    const offset = parseInt(req.query.offset) || 0;

    const transactions = await getTransactionHistory(
      req.params.id,
      { limit, offset }
    );

    return res.json({
      success: true,
      data: {
        transactions,
        limit,
        offset,
      },
    });

  } catch (err) {
    console.error('Get transactions error:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch transactions.',
    });
  }
};

/**
 * PATCH /api/v1/accounts/:id/status
 *
 * Freeze, unfreeze or mark an account dormant.
 * Customer can freeze their own account
 * (e.g. if they lose their card).
 */
const updateStatus = async (req, res) => {
  try {
    const { status } = req.body;

    const validStatuses = ['active', 'frozen', 'dormant'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
      });
    }

    // Verify account belongs to customer before changing anything
    const account = await accountModel.getAccountById(
      req.params.id,
      req.customer.id
    );

    if (!account) {
      return res.status(404).json({
        success: false,
        message: 'Account not found.',
      });
    }

    const updated = await accountModel.updateAccountStatus(
      req.params.id,
      status,
      req.customer.id
    );

    return res.json({
      success: true,
      message: `Account ${status} successfully.`,
      data: { account: updated },
    });

  } catch (err) {
    console.error('Update status error:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to update account status.',
    });
  }
};

module.exports = {
  createAccount,
  getMyAccounts,
  getAccount,
  getBalance,
  getAccountTransactions,
  updateStatus,
};