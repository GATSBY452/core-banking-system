const jwt = require('jsonwebtoken');
const db = require('../db');

/**
 * PROTECT MIDDLEWARE
 *
 * Sits in front of every protected route.
 * The request cannot pass through unless it has a valid token.
 *
 * Flow:
 *   Request arrives
 *       │
 *       ▼
 *   Is there a Bearer token in the header?
 *       │
 *   NO  → reject with 401
 *   YES → verify the token is genuine
 *       │
 *   FAKE/EXPIRED → reject with 401
 *   GENUINE      → check customer still exists and is active
 *       │
 *   NOT FOUND/SUSPENDED → reject with 401
 *   FOUND ACTIVE        → attach customer to request → pass through
 */
const protect = async (req, res, next) => {
  try {
    // Step 1 — Check the Authorization header exists
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.',
      });
    }

    // Step 2 — Extract the token
    // Header looks like: "Bearer eyJhbGciOiJIUzI1NiJ9..."
    // We split on space and take the second part
    const token = authHeader.split(' ')[1];

    // Step 3 — Verify the token is genuine and not expired
    // jwt.verify throws an error if anything is wrong
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Step 4 — Check the customer still exists and is active
    // Token could be valid but customer might have been suspended
    const result = await db.query(
      `SELECT id, first_name, last_name, email, phone, kyc_status, status
       FROM customers
       WHERE id = $1 AND status = 'active'`,
      [decoded.id]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Customer not found or account suspended.',
      });
    }

    // Step 5 — Attach customer to the request object
    // Now every controller can access req.customer
    req.customer = result.rows[0];

    // Step 6 — Pass control to the next function (the controller)
    next();

  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expired. Please log in again.',
      });
    }
    return res.status(401).json({
      success: false,
      message: 'Invalid token.',
    });
  }
};

/**
 * GENERATE TOKENS
 *
 * Called after successful login or registration.
 * Creates a JWT token that expires in 24 hours.
 *
 * The token contains the customer ID — nothing else.
 * When the token arrives on future requests,
 * we use the ID to look up the full customer from the database.
 */
const generateTokens = (customerId) => {
  const accessToken = jwt.sign(
    { id: customerId },          // payload — what we store inside the token
    process.env.JWT_SECRET,      // secret key — used to sign and verify
    { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
  );
  return { accessToken };
};

module.exports = { protect, generateTokens };