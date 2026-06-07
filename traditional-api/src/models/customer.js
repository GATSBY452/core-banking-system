const db = require('../db');
const bcrypt = require('bcryptjs');
const { generateAccountNumber } = require('../engines/ledger');

/**
 * Create a new customer with a default savings account
 * Both happen atomically — either both succeed or neither does
 */
const createCustomer = async ({
  firstName,
  lastName,
  email,
  phone,
  password,
  dateOfBirth,
  address
}) => {
  return db.transaction(async (client) => {

    // Rule 5: NEVER store plain passwords
    // bcrypt scrambles it so even we can't read it
    // 12 = how many times it scrambles (higher = more secure but slower)
    const passwordHash = await bcrypt.hash(password, 12);

    // Create the customer row
    const customerResult = await client.query(
      `INSERT INTO customers
         (first_name, last_name, email, phone, password_hash, date_of_birth, address)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, first_name, last_name, email, phone, kyc_status, status, created_at`,
      [firstName, lastName, email, phone, passwordHash, dateOfBirth, address]
    );
    const customer = customerResult.rows[0];

    // Auto-create a default savings account for every new customer
    const accountNumber = generateAccountNumber();
    const accountResult = await client.query(
      `INSERT INTO accounts
         (customer_id, account_number, account_type, account_name, currency)
       VALUES ($1, $2, 'savings', $3, 'USD')
       RETURNING *`,
      [customer.id, accountNumber, `${firstName} ${lastName} - Savings`]
    );

    // Write to audit log — who was created and when
    await client.query(
      `INSERT INTO audit_logs
         (entity_type, entity_id, action, new_data)
       VALUES ('customer', $1, 'created', $2)`,
      [customer.id, JSON.stringify({ email, phone, firstName, lastName })]
    );

    return { customer, account: accountResult.rows[0] };
  });
};

/**
 * Find a customer by their email address
 * Used during login
 * Returns the full row including password_hash
 */
const findByEmail = async (email) => {
  const result = await db.query(
    'SELECT * FROM customers WHERE email = $1',
    [email]
  );
  return result.rows[0] || null;
};

/**
 * Find a customer by their ID
 * Safe version — never returns the password hash
 * Used after login to return customer data
 */
const findById = async (id) => {
  const result = await db.query(
    `SELECT
       id, first_name, last_name, email, phone,
       date_of_birth, address, kyc_status, status, created_at
     FROM customers
     WHERE id = $1`,
    [id]
  );
  return result.rows[0] || null;
};

/**
 * Verify a plain password against the stored hash
 * Returns true if correct, false if wrong
 * bcrypt does the comparison safely
 */
const verifyPassword = async (plainPassword, hash) => {
  return bcrypt.compare(plainPassword, hash);
};

/**
 * Update customer KYC information
 * KYC = Know Your Customer (ID verification)
 */
const updateKYC = async (customerId, {
  idType,
  idNumber,
  address,
  kycStatus
}) => {
  const result = await db.query(
    `UPDATE customers
     SET
       id_type    = COALESCE($1, id_type),
       id_number  = COALESCE($2, id_number),
       address    = COALESCE($3, address),
       kyc_status = COALESCE($4, kyc_status),
       updated_at = NOW()
     WHERE id = $5
     RETURNING id, first_name, last_name, email, kyc_status, updated_at`,
    [idType, idNumber, address, kycStatus, customerId]
  );
  return result.rows[0];
};

module.exports = {
  createCustomer,
  findByEmail,
  findById,
  verifyPassword,
  updateKYC
};