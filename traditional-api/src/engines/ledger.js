/**
 * LEDGER ENGINE
 * The heart of the core banking system.
 *
 * Rules enforced here:
 * Rule 1: Balance is NEVER stored — always calculated from ledger entries
 * Rule 2: Every transaction is atomic — all entries succeed or all fail
 * Double-entry: Every transaction creates minimum 2 entries that net to ZERO
 */

const db = require('../db');

// ============================================================
// HELPERS
// ============================================================

// Generates a unique transaction reference like TXN-20260606-AB12CD
const generateReference = () => {
  const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const random = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `TXN-${date}-${random}`;
};

// Generates a unique account number like ACC1234567890
const generateAccountNumber = () => {
  const timestamp = Date.now().toString().slice(-8);
  const random = Math.floor(Math.random() * 100).toString().padStart(2, '0');
  return `ACC${timestamp}${random}`;
};

// ============================================================
// RULE 1: Balance is ALWAYS calculated from ledger entries
// We NEVER store a balance directly in the accounts table
// ============================================================
const getBalance = async (accountId, client = null) => {
  const runner = client || db;
  const result = await runner.query(
    `SELECT COALESCE(
       SUM(CASE WHEN entry_type = 'CREDIT' THEN amount ELSE -amount END),
       0
     ) AS balance
     FROM ledger_entries
     WHERE account_id = $1`,
    [accountId]
  );
  return parseFloat(result.rows[0].balance);
};

// ============================================================
// INTERNAL: Creates one side of a double entry
// Always called in pairs — never alone
// ============================================================
const createLedgerEntry = async (client, {
  transactionId,
  accountId,
  systemAccountId,
  entryType,
  amount,
  currency = 'USD',
  description,
}) => {
  // Calculate the running balance after this entry
  let runningBalance = 0;
  if (accountId) {
    runningBalance = await getBalance(accountId, client);
    runningBalance += entryType === 'CREDIT' ? amount : -amount;
  }

  const result = await client.query(
    `INSERT INTO ledger_entries
       (transaction_id, account_id, system_account_id,
        entry_type, amount, currency, running_balance, description)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING *`,
    [
      transactionId,
      accountId || null,
      systemAccountId || null,
      entryType,
      amount,
      currency,
      runningBalance,
      description
    ]
  );
  return result.rows[0];
};

// ============================================================
// DEPOSIT
//
// Double entry:
//   DEBIT  → Bank Vault (cash comes into the bank)
//   CREDIT → Customer Account (customer's balance goes up)
// ============================================================
const deposit = async ({
  accountId,
  amount,
  description,
  initiatedBy,
  idempotencyKey,
  metadata = {}
}) => {
  return db.transaction(async (client) => {

    // Rule 4: Check idempotency — same request sent twice = process once
    if (idempotencyKey) {
      const existing = await client.query(
        'SELECT id, status FROM transactions WHERE idempotency_key = $1',
        [idempotencyKey]
      );
      if (existing.rows.length > 0) {
        return { duplicate: true, transaction: existing.rows[0] };
      }
    }

    // Check account exists and is active
    const accountResult = await client.query(
      'SELECT * FROM accounts WHERE id = $1 AND status = $2',
      [accountId, 'active']
    );
    if (accountResult.rows.length === 0) {
      throw new Error('Account not found or inactive');
    }

    // Get the bank vault system account
    const vaultResult = await client.query(
      "SELECT id FROM system_accounts WHERE account_type = 'vault' LIMIT 1"
    );
    const vaultId = vaultResult.rows[0].id;

    // Create the parent transaction record
    const txnResult = await client.query(
      `INSERT INTO transactions
         (reference, type, description, amount, status,
          idempotency_key, initiated_by, metadata)
       VALUES ($1, 'deposit', $2, $3, 'successful', $4, $5, $6)
       RETURNING *`,
      [
        generateReference(),
        description || 'Cash Deposit',
        amount,
        idempotencyKey,
        initiatedBy,
        JSON.stringify(metadata)
      ]
    );
    const txn = txnResult.rows[0];

    // DEBIT: Bank Vault (cash physically arrives at bank)
    await createLedgerEntry(client, {
      transactionId:    txn.id,
      systemAccountId:  vaultId,
      entryType:        'DEBIT',
      amount,
      description:      `Deposit received - ${txn.reference}`,
    });

    // CREDIT: Customer Account (customer's money goes up)
    await createLedgerEntry(client, {
      transactionId: txn.id,
      accountId,
      entryType:     'CREDIT',
      amount,
      description:   `Deposit credited - ${txn.reference}`,
    });

    // Return the result including the new balance
    const newBalance = await getBalance(accountId, client);
    return { transaction: txn, newBalance };
  });
};

// ============================================================
// WITHDRAWAL
//
// Double entry:
//   DEBIT  → Customer Account (customer's balance goes down)
//   CREDIT → Bank Vault (cash leaves the bank)
// ============================================================
const withdraw = async ({
  accountId,
  amount,
  description,
  initiatedBy,
  idempotencyKey,
  metadata = {}
}) => {
  return db.transaction(async (client) => {

    if (idempotencyKey) {
      const existing = await client.query(
        'SELECT id, status FROM transactions WHERE idempotency_key = $1',
        [idempotencyKey]
      );
      if (existing.rows.length > 0) {
        return { duplicate: true, transaction: existing.rows[0] };
      }
    }

    // Check account exists and is active
    const accountResult = await client.query(
      'SELECT * FROM accounts WHERE id = $1 AND status = $2',
      [accountId, 'active']
    );
    if (accountResult.rows.length === 0) {
      throw new Error('Account not found or inactive');
    }
    const account = accountResult.rows[0];

    // Check the customer has enough money
    const currentBalance = await getBalance(accountId, client);
    const availableBalance = currentBalance + parseFloat(account.overdraft_limit);
    if (availableBalance < amount) {
      throw new Error(`Insufficient funds. Available: ${currentBalance.toFixed(2)}`);
    }

    // Get the bank vault
    const vaultResult = await client.query(
      "SELECT id FROM system_accounts WHERE account_type = 'vault' LIMIT 1"
    );
    const vaultId = vaultResult.rows[0].id;

    // Create parent transaction
    const txnResult = await client.query(
      `INSERT INTO transactions
         (reference, type, description, amount, status,
          idempotency_key, initiated_by, metadata)
       VALUES ($1, 'withdrawal', $2, $3, 'successful', $4, $5, $6)
       RETURNING *`,
      [
        generateReference(),
        description || 'Cash Withdrawal',
        amount,
        idempotencyKey,
        initiatedBy,
        JSON.stringify(metadata)
      ]
    );
    const txn = txnResult.rows[0];

    // DEBIT: Customer Account (balance goes down)
    await createLedgerEntry(client, {
      transactionId: txn.id,
      accountId,
      entryType:     'DEBIT',
      amount,
      description:   `Withdrawal debited - ${txn.reference}`,
    });

    // CREDIT: Bank Vault (cash leaves the bank)
    await createLedgerEntry(client, {
      transactionId:   txn.id,
      systemAccountId: vaultId,
      entryType:       'CREDIT',
      amount,
      description:     `Withdrawal paid - ${txn.reference}`,
    });

    const newBalance = await getBalance(accountId, client);
    return { transaction: txn, newBalance };
  });
};

// ============================================================
// TRANSFER
//
// Double entry:
//   DEBIT  → Sender Account (their balance goes down)
//   CREDIT → Receiver Account (their balance goes up)
// ============================================================
const transfer = async ({
  fromAccountId,
  toAccountId,
  amount,
  description,
  initiatedBy,
  idempotencyKey,
  metadata = {},
  fee = 0
}) => {
  return db.transaction(async (client) => {

    if (idempotencyKey) {
      const existing = await client.query(
        'SELECT id, status FROM transactions WHERE idempotency_key = $1',
        [idempotencyKey]
      );
      if (existing.rows.length > 0) {
        return { duplicate: true, transaction: existing.rows[0] };
      }
    }

    // Check sender account
    const senderResult = await client.query(
      'SELECT * FROM accounts WHERE id = $1 AND status = $2',
      [fromAccountId, 'active']
    );
    if (senderResult.rows.length === 0) {
      throw new Error('Sender account not found or inactive');
    }
    const sender = senderResult.rows[0];

    // Check receiver account
    const receiverResult = await client.query(
      'SELECT * FROM accounts WHERE id = $1 AND status = $2',
      [toAccountId, 'active']
    );
    if (receiverResult.rows.length === 0) {
      throw new Error('Receiver account not found or inactive');
    }

    // Check sender has enough money (including any fee)
    const senderBalance = await getBalance(fromAccountId, client);
    const totalNeeded = amount + fee;
    const available = senderBalance + parseFloat(sender.overdraft_limit);
    if (available < totalNeeded) {
      throw new Error(
        `Insufficient funds. Available: ${senderBalance.toFixed(2)}, needed: ${totalNeeded.toFixed(2)}`
      );
    }

    // Create parent transaction
    const txnResult = await client.query(
      `INSERT INTO transactions
         (reference, type, description, amount, status,
          idempotency_key, initiated_by, metadata)
       VALUES ($1, 'transfer', $2, $3, 'successful', $4, $5, $6)
       RETURNING *`,
      [
        generateReference(),
        description || 'Account Transfer',
        amount,
        idempotencyKey,
        initiatedBy,
        JSON.stringify(metadata)
      ]
    );
    const txn = txnResult.rows[0];

    // DEBIT: Sender (money leaves their account)
    await createLedgerEntry(client, {
      transactionId: txn.id,
      accountId:     fromAccountId,
      entryType:     'DEBIT',
      amount,
      description:   `Transfer sent - ${txn.reference}`,
    });

    // CREDIT: Receiver (money arrives in their account)
    await createLedgerEntry(client, {
      transactionId: txn.id,
      accountId:     toAccountId,
      entryType:     'CREDIT',
      amount,
      description:   `Transfer received - ${txn.reference}`,
    });

    // Optional fee — charged to sender, goes to bank fees account
    if (fee > 0) {
      const feesResult = await client.query(
        "SELECT id FROM system_accounts WHERE account_type = 'fees' LIMIT 1"
      );
      const feesAccountId = feesResult.rows[0].id;

      await createLedgerEntry(client, {
        transactionId: txn.id,
        accountId:     fromAccountId,
        entryType:     'DEBIT',
        amount:        fee,
        description:   `Transfer fee - ${txn.reference}`,
      });

      await createLedgerEntry(client, {
        transactionId:   txn.id,
        systemAccountId: feesAccountId,
        entryType:       'CREDIT',
        amount:          fee,
        description:     `Fee collected - ${txn.reference}`,
      });
    }

    const newSenderBalance = await getBalance(fromAccountId, client);
    return { transaction: txn, newSenderBalance };
  });
};

// ============================================================
// REVERSE
// Creates mirror entries with opposite debit/credit
// Nothing is deleted — both transactions stay in history
// ============================================================
const reverse = async ({ transactionId, reason, initiatedBy }) => {
  return db.transaction(async (client) => {

    // Find the original transaction
    const originalResult = await client.query(
      "SELECT * FROM transactions WHERE id = $1 AND status = 'successful'",
      [transactionId]
    );
    if (originalResult.rows.length === 0) {
      throw new Error('Transaction not found or cannot be reversed');
    }
    const original = originalResult.rows[0];

    // Get all ledger entries for that transaction
    const entriesResult = await client.query(
      'SELECT * FROM ledger_entries WHERE transaction_id = $1',
      [transactionId]
    );
    const entries = entriesResult.rows;

    // Create a new reversal transaction
    const reversalResult = await client.query(
      `INSERT INTO transactions
         (reference, type, description, amount, status, initiated_by, reversed_by)
       VALUES ($1, 'reversal', $2, $3, 'successful', $4, $5)
       RETURNING *`,
      [
        generateReference(),
        reason || `Reversal of ${original.reference}`,
        original.amount,
        initiatedBy,
        transactionId
      ]
    );
    const reversal = reversalResult.rows[0];

    // Mirror every entry with the opposite type
    for (const entry of entries) {
      await createLedgerEntry(client, {
        transactionId:   reversal.id,
        accountId:       entry.account_id,
        systemAccountId: entry.system_account_id,
        entryType:       entry.entry_type === 'DEBIT' ? 'CREDIT' : 'DEBIT',
        amount:          entry.amount,
        description:     `Reversal: ${entry.description}`,
      });
    }

    // Mark original as reversed
    await client.query(
      "UPDATE transactions SET status = 'reversed', updated_at = NOW() WHERE id = $1",
      [transactionId]
    );

    return { reversal, original };
  });
};

// ============================================================
// TRANSACTION HISTORY for an account
// ============================================================
const getTransactionHistory = async (accountId, { limit = 20, offset = 0 } = {}) => {
  const result = await db.query(
    `SELECT
       t.id, t.reference, t.type, t.description,
       t.amount, t.status, t.created_at,
       le.entry_type, le.running_balance
     FROM ledger_entries le
     JOIN transactions t ON t.id = le.transaction_id
     WHERE le.account_id = $1
     ORDER BY le.created_at DESC
     LIMIT $2 OFFSET $3`,
    [accountId, limit, offset]
  );
  return result.rows;
};

module.exports = {
  deposit,
  withdraw,
  transfer,
  reverse,
  getBalance,
  getTransactionHistory,
  generateAccountNumber,
  generateReference,
};