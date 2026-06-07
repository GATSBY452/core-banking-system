const db = require('../db');
const { generateAccountNumber, getBalance } = require('../engines/ledger');

/**
 * Create a new account for an existing customer
 * Called when customer wants an additional account
 * (they already got one savings account when they registered)
 */
const createAccount = async ({
  customerId,
  accountType,
  accountName,
  currency = 'USD',
  overdraftLimit = 0,
  interestRate = 0
}) => {
  const accountNumber = generateAccountNumber();

  const result = await db.query(
    `INSERT INTO accounts
       (customer_id, account_number, account_type,
        account_name, currency, overdraft_limit, interest_rate)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [customerId, accountNumber, accountType,
     accountName, currency, overdraftLimit, interestRate]
  );

  // Write to audit log
  await db.query(
    `INSERT INTO audit_logs
       (entity_type, entity_id, action, performed_by, new_data)
     VALUES ('account', $1, 'created', $2, $3)`,
    [
      result.rows[0].id,
      customerId,
      JSON.stringify({ accountType, accountNumber })
    ]
  );

  return result.rows[0];
};

/**
 * Get ALL accounts for a customer
 * Each account includes its LIVE balance calculated from ledger
 * This is what the iOS app shows on the home screen
 */
const getCustomerAccounts = async (customerId) => {
  const result = await db.query(
    `SELECT
       a.*,
       COALESCE(
         SUM(CASE WHEN le.entry_type = 'CREDIT' THEN le.amount
                  ELSE -le.amount END),
         0
       ) AS balance
     FROM accounts a
     LEFT JOIN ledger_entries le ON le.account_id = a.id
     WHERE a.customer_id = $1
     GROUP BY a.id
     ORDER BY a.created_at ASC`,
    [customerId]
  );
  return result.rows;
};

/**
 * Get a single account by its ID
 * Includes live balance from ledger
 * Optional: scope to a specific customer (security check)
 */
const getAccountById = async (accountId, customerId = null) => {
  // Build the query dynamically
  // If customerId is provided, only return account if it belongs to them
  let queryText = `
    SELECT
      a.*,
      COALESCE(
        SUM(CASE WHEN le.entry_type = 'CREDIT' THEN le.amount
                 ELSE -le.amount END),
        0
      ) AS balance
    FROM accounts a
    LEFT JOIN ledger_entries le ON le.account_id = a.id
    WHERE a.id = $1`;

  const params = [accountId];

  // Security: if customerId provided, make sure this account belongs to them
  if (customerId) {
    queryText += ` AND a.customer_id = $2`;
    params.push(customerId);
  }

  queryText += ` GROUP BY a.id`;

  const result = await db.query(queryText, params);
  return result.rows[0] || null;
};

/**
 * Get account by account number
 * Used during transfers — receiver is identified by account number
 */
const getAccountByNumber = async (accountNumber) => {
  const result = await db.query(
    'SELECT * FROM accounts WHERE account_number = $1',
    [accountNumber]
  );
  return result.rows[0] || null;
};

/**
 * Update account status
 * active   → account works normally
 * frozen   → no transactions allowed (fraud protection)
 * dormant  → inactive for a long time
 * closed   → permanently shut
 */
const updateAccountStatus = async (accountId, status, performedBy) => {
  // Get old status for audit log
  const oldAccount = await db.query(
    'SELECT status FROM accounts WHERE id = $1',
    [accountId]
  );

  const result = await db.query(
    `UPDATE accounts
     SET status = $1, updated_at = NOW()
     WHERE id = $2
     RETURNING *`,
    [status, accountId]
  );

  // Write to audit log — who changed what and when
  if (result.rows.length > 0) {
    await db.query(
      `INSERT INTO audit_logs
         (entity_type, entity_id, action, performed_by, old_data, new_data)
       VALUES ('account', $1, $2, $3, $4, $5)`,
      [
        accountId,
        `status_changed_to_${status}`,
        performedBy,
        JSON.stringify({ status: oldAccount.rows[0]?.status }),
        JSON.stringify({ status })
      ]
    );
  }

  return result.rows[0] || null;
};

module.exports = {
  createAccount,
  getCustomerAccounts,
  getAccountById,
  getAccountByNumber,
  updateAccountStatus
};