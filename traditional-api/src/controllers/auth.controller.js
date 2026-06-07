const customerModel = require('../models/customer');
const { generateTokens } = require('../middleware/auth');

/**
 * POST /api/v1/auth/register
 *
 * What happens:
 * 1. Check email not already taken
 * 2. Create customer + savings account (atomic)
 * 3. Generate JWT token
 * 4. Return customer, account, and token
 */
const register = async (req, res) => {
  try {
    const {
      firstName,
      lastName,
      email,
      phone,
      password,
      dateOfBirth,
      address
    } = req.body;

    // Basic validation — make sure required fields exist
    if (!firstName || !lastName || !email || !phone || !password) {
      return res.status(400).json({
        success: false,
        message: 'firstName, lastName, email, phone and password are required.',
      });
    }

    // Check if email already registered
    const existing = await customerModel.findByEmail(email);
    if (existing) {
      return res.status(409).json({
        success: false,
        message: 'Email already registered.',
      });
    }

    // Create the customer and their first savings account
    const { customer, account } = await customerModel.createCustomer({
      firstName,
      lastName,
      email,
      phone,
      password,
      dateOfBirth,
      address,
    });

    // Generate JWT token so they are instantly logged in
    const { accessToken } = generateTokens(customer.id);

    // Send back everything the app needs
    return res.status(201).json({
      success: true,
      message: 'Account created successfully.',
      data: {
        customer,
        account: {
          id:            account.id,
          accountNumber: account.account_number,
          accountType:   account.account_type,
          accountName:   account.account_name,
          currency:      account.currency,
          balance:       0,
        },
        accessToken,
      },
    });

  } catch (err) {
    console.error('Register error:', err);

    // Handle duplicate email or phone (database constraint)
    if (err.code === '23505') {
      return res.status(409).json({
        success: false,
        message: 'Email or phone already registered.',
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Registration failed. Please try again.',
    });
  }
};

/**
 * POST /api/v1/auth/login
 *
 * What happens:
 * 1. Find customer by email
 * 2. Check account is active
 * 3. Verify password against stored hash
 * 4. Generate JWT token
 * 5. Return customer data and token
 */
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Basic validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required.',
      });
    }

    // Find customer by email
    // findByEmail returns full row including password_hash
    const customer = await customerModel.findByEmail(email);
    if (!customer) {
      // Deliberately vague — don't tell them which part was wrong
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.',
      });
    }

    // Check account is not suspended or closed
    if (customer.status !== 'active') {
      return res.status(403).json({
        success: false,
        message: 'Account is suspended or closed. Contact support.',
      });
    }

    // Verify password against the stored hash
    const isValid = await customerModel.verifyPassword(
      password,
      customer.password_hash
    );
    if (!isValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.',
      });
    }

    // Generate fresh token
    const { accessToken } = generateTokens(customer.id);

    // Return customer data — never return password_hash
    return res.json({
      success: true,
      message: 'Login successful.',
      data: {
        customer: {
          id:        customer.id,
          firstName: customer.first_name,
          lastName:  customer.last_name,
          email:     customer.email,
          phone:     customer.phone,
          kycStatus: customer.kyc_status,
          status:    customer.status,
        },
        accessToken,
      },
    });

  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({
      success: false,
      message: 'Login failed. Please try again.',
    });
  }
};

/**
 * GET /api/v1/auth/me
 *
 * Returns the currently logged in customer's profile.
 * Protected route — req.customer is set by the protect middleware.
 */
const getMe = async (req, res) => {
  try {
    // req.customer was attached by protect middleware
    // We call findById to get fresh data without password_hash
    const customer = await customerModel.findById(req.customer.id);

    return res.json({
      success: true,
      data: { customer },
    });

  } catch (err) {
    console.error('GetMe error:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch profile.',
    });
  }
};

module.exports = { register, login, getMe };