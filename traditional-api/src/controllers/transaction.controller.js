const ledger = require('../engines/ledger');
const accountModel = require('../models/account');
const db = require('../db');

/**
 * POST /api/v1/transactions/deposit
 *
 * Customer deposits money into their account.
 * Ledger engine handles the double entry:
 *   DEBIT  Bank Vault
 *   CREDIT Customer Account
 */
const deposit = async (req, res) => {
  try {
    const { accountId, amount, description } = req.body;
    const idempotencyKey = req.headers['idempotency-key'];

    // Validate inputs
    if (!accountId || !amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'accountId and a positive amount are required.',
      });
    }

    // Security: verify account belongs to logged in customer
    const account = await accountModel.getAccountById(
      accountId,
      req.customer.id
    );
    if (!account) {
      return res.status(404).json({
        success: false,
        message: 'Account not found.',
      });
    }

    // Call the ledger engine — this does the actual banking work
    const result = await ledger.deposit({
      accountId,
      amount:         parseFloat(amount),
      description,
      initiatedBy:    req.customer.id,
      idempotencyKey,
      metadata: {
        ip:      req.ip,
        channel: 'mobile_app',
      },
    });

    // Handle duplicate request
    if (result.duplicate) {
      return res.status(200).json({
        success: true,
        message: 'Duplicate request — original transaction returned.',
        data: result,
      });
    }

    return res.status(201).json({
      success: true,
      message: `Deposit of ${amount} successful.`,
      data: {
        transaction: result.transaction,
        newBalance:  result.newBalance,
      },
    });

  } catch (err) {
    console.error('Deposit error:', err);
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }
};

/**
 * POST /api/v1/transactions/withdraw
 *
 * Customer withdraws money from their account.
 * Ledger engine handles the double entry:
 *   DEBIT  Customer Account
 *   CREDIT Bank Vault
 */
const withdraw = async (req, res) => {
  try {
    const { accountId, amount, description } = req.body;
    const idempotencyKey = req.headers['idempotency-key'];

    if (!accountId || !amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'accountId and a positive amount are required.',
      });
    }

    // Security: verify account belongs to logged in customer
    const account = await accountModel.getAccountById(
      accountId,
      req.customer.id
    );
    if (!account) {
      return res.status(404).json({
        success: false,
        message: 'Account not found.',
      });
    }

    const result = await ledger.withdraw({
      accountId,
      amount:         parseFloat(amount),
      description,
      initiatedBy:    req.customer.id,
      idempotencyKey,
      metadata: {
        ip:      req.ip,
        channel: 'mobile_app',
      },
    });

    if (result.duplicate) {
      return res.status(200).json({
        success: true,
        message: 'Duplicate request — original transaction returned.',
        data: result,
      });
    }

    return res.status(201).json({
      success: true,
      message: `Withdrawal of ${amount} successful.`,
      data: {
        transaction: result.transaction,
        newBalance:  result.newBalance,
      },
    });

  } catch (err) {
    console.error('Withdraw error:', err);
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }
};

/**
 * POST /api/v1/transactions/transfer
 *
 * Move money from one account to another.
 * Receiver is identified by their account NUMBER.
 * Ledger engine handles the double entry:
 *   DEBIT  Sender Account
 *   CREDIT Receiver Account
 */
const transfer = async (req, res) => {
  try {
    const { fromAccountId, toAccountNumber, amount, description } = req.body;
    const idempotencyKey = req.headers['idempotency-key'];

    if (!fromAccountId || !toAccountNumber || !amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'fromAccountId, toAccountNumber and a positive amount are required.',
      });
    }

    // Security: verify sender account belongs to logged in customer
    const senderAccount = await accountModel.getAccountById(
      fromAccountId,
      req.customer.id
    );
    if (!senderAccount) {
      return res.status(404).json({
        success: false,
        message: 'Sender account not found.',
      });
    }

    // Look up receiver by account number
    const receiverAccount = await accountModel.getAccountByNumber(toAccountNumber);
    if (!receiverAccount) {
      return res.status(404).json({
        success: false,
        message: 'Receiver account not found.',
      });
    }

    // Cannot transfer to yourself
    if (fromAccountId === receiverAccount.id) {
      return res.status(400).json({
        success: false,
        message: 'Cannot transfer to the same account.',
      });
    }

    const result = await ledger.transfer({
      fromAccountId,
      toAccountId:    receiverAccount.id,
      amount:         parseFloat(amount),
      description,
      initiatedBy:    req.customer.id,
      idempotencyKey,
      metadata: {
        ip:              req.ip,
        channel:         'mobile_app',
        toAccountNumber,
      },
    });

    if (result.duplicate) {
      return res.status(200).json({
        success: true,
        message: 'Duplicate request — original transaction returned.',
        data: result,
      });
    }

    return res.status(201).json({
      success: true,
      message: `Transfer of ${amount} to ${toAccountNumber} successful.`,
      data: {
        transaction:      result.transaction,
        newSenderBalance: result.newSenderBalance,
      },
    });

  } catch (err) {
    console.error('Transfer error:', err);
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }
};

/**
 * POST /api/v1/transactions/:id/reverse
 *
 * Reverse a completed transaction.
 * Creates mirror ledger entries with opposite debit/credit.
 * Original transaction is marked as reversed.
 * Nothing is deleted — full audit trail preserved.
 */
const reverse = async (req, res) => {
  try {
    const { reason } = req.body;

    const result = await ledger.reverse({
      transactionId: req.params.id,
      reason,
      initiatedBy:   req.customer.id,
    });

    return res.json({
      success: true,
      message: 'Transaction reversed successfully.',
      data:    result,
    });

  } catch (err) {
    console.error('Reverse error:', err);
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }
};

/**
 * GET /api/v1/transactions/:id
 *
 * Get a single transaction with its ledger entries.
 * Shows the full double entry — both sides of the transaction.
 * This is what makes it transparent and auditable.
 */
const getTransaction = async (req, res) => {
  try {
    const txnResult = await db.query(
      'SELECT * FROM transactions WHERE id = $1',
      [req.params.id]
    );

    if (txnResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found.',
      });
    }

    const transaction = txnResult.rows[0];

    // Get both ledger entries — shows the full double entry
    const entriesResult = await db.query(
      `SELECT * FROM ledger_entries
       WHERE transaction_id = $1
       ORDER BY created_at ASC`,
      [req.params.id]
    );

    return res.json({
      success: true,
      data: {
        transaction,
        ledgerEntries: entriesResult.rows,
      },
    });

  } catch (err) {
    console.error('Get transaction error:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch transaction.',
    });
  }
};

module.exports = { deposit, withdraw, transfer, reverse, getTransaction };