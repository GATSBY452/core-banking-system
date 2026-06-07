-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. CUSTOMERS
-- Every person who has an account in our bank
-- ============================================================
CREATE TABLE IF NOT EXISTS customers (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  first_name    VARCHAR(100) NOT NULL,
  last_name     VARCHAR(100) NOT NULL,
  email         VARCHAR(255) UNIQUE NOT NULL,
  phone         VARCHAR(20) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  date_of_birth DATE,
  address       TEXT,
  id_type       VARCHAR(50),
  id_number     VARCHAR(100),
  kyc_status    VARCHAR(20) DEFAULT 'pending',
  status        VARCHAR(20) DEFAULT 'active',
  created_at    TIMESTAMP DEFAULT NOW(),
  updated_at    TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 2. ACCOUNTS
-- One customer can have many accounts (savings, current, wallet)
-- ============================================================
CREATE TABLE IF NOT EXISTS accounts (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id     UUID NOT NULL REFERENCES customers(id),
  account_number  VARCHAR(20) UNIQUE NOT NULL,
  account_type    VARCHAR(30) NOT NULL,
  account_name    VARCHAR(200) NOT NULL,
  currency        VARCHAR(3) DEFAULT 'USD',
  status          VARCHAR(20) DEFAULT 'active',
  overdraft_limit NUMERIC(19,4) DEFAULT 0,
  interest_rate   NUMERIC(5,4) DEFAULT 0,
  created_at      TIMESTAMP DEFAULT NOW(),
  updated_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 3. SYSTEM ACCOUNTS
-- The bank's own internal accounts (vault, revenue, fees)
-- ============================================================
CREATE TABLE IF NOT EXISTS system_accounts (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_number  VARCHAR(20) UNIQUE NOT NULL,
  account_name    VARCHAR(200) NOT NULL,
  account_type    VARCHAR(30) NOT NULL,
  currency        VARCHAR(3) DEFAULT 'USD',
  created_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 4. TRANSACTIONS
-- The parent record for every financial event
-- Each one spawns minimum 2 ledger entries
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reference         VARCHAR(50) UNIQUE NOT NULL,
  type              VARCHAR(30) NOT NULL,
  description       TEXT NOT NULL,
  amount            NUMERIC(19,4) NOT NULL CHECK (amount > 0),
  currency          VARCHAR(3) DEFAULT 'USD',
  status            VARCHAR(20) DEFAULT 'pending',
  idempotency_key   VARCHAR(100) UNIQUE,
  initiated_by      UUID REFERENCES customers(id),
  metadata          JSONB DEFAULT '{}',
  reversed_by       UUID REFERENCES transactions(id),
  created_at        TIMESTAMP DEFAULT NOW(),
  updated_at        TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 5. LEDGER ENTRIES
-- THE MOST IMPORTANT TABLE
-- Every debit and credit lives here
-- Balance is ALWAYS calculated from this table — never stored
-- ============================================================
CREATE TABLE IF NOT EXISTS ledger_entries (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id    UUID NOT NULL REFERENCES transactions(id),
  account_id        UUID,
  system_account_id UUID,
  entry_type        VARCHAR(10) NOT NULL CHECK (entry_type IN ('DEBIT', 'CREDIT')),
  amount            NUMERIC(19,4) NOT NULL CHECK (amount > 0),
  currency          VARCHAR(3) DEFAULT 'USD',
  running_balance   NUMERIC(19,4),
  description       TEXT,
  created_at        TIMESTAMP DEFAULT NOW(),

  CONSTRAINT account_xor_system CHECK (
    (account_id IS NOT NULL AND system_account_id IS NULL) OR
    (account_id IS NULL AND system_account_id IS NOT NULL)
  )
);

-- ============================================================
-- 6. AUDIT LOGS
-- Every action ever taken — who, what, when, why
-- Your legal protection
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_type  VARCHAR(50) NOT NULL,
  entity_id    UUID NOT NULL,
  action       VARCHAR(50) NOT NULL,
  performed_by UUID REFERENCES customers(id),
  old_data     JSONB,
  new_data     JSONB,
  ip_address   VARCHAR(45),
  user_agent   TEXT,
  created_at   TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 7. REFRESH TOKENS
-- Keeps users logged in safely
-- ============================================================
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL REFERENCES customers(id),
  token       TEXT NOT NULL UNIQUE,
  expires_at  TIMESTAMP NOT NULL,
  revoked     BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- INDEXES — makes searches faster
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_accounts_customer_id ON accounts(customer_id);
CREATE INDEX IF NOT EXISTS idx_ledger_account_id ON ledger_entries(account_id);
CREATE INDEX IF NOT EXISTS idx_ledger_transaction_id ON ledger_entries(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_reference ON transactions(reference);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs(entity_type, entity_id);

-- ============================================================
-- SEED DATA — Bank's internal system accounts
-- Created once when schema runs
-- ============================================================
INSERT INTO system_accounts (account_number, account_name, account_type) VALUES
  ('SYS-VAULT-001', 'Bank Vault (Cash)',    'vault'),
  ('SYS-REV-001',   'Bank Revenue',         'revenue'),
  ('SYS-FEES-001',  'Bank Fees Collected',  'fees'),
  ('SYS-SUSP-001',  'Suspense Account',     'suspense')
ON CONFLICT (account_number) DO NOTHING;

-- ============================================================
-- VIEW — Live balance calculated from ledger (never stored)
-- ============================================================
CREATE OR REPLACE VIEW account_balances AS
SELECT
  a.id AS account_id,
  a.account_number,
  a.account_name,
  a.account_type,
  a.currency,
  a.status,
  COALESCE(
    SUM(CASE WHEN le.entry_type = 'CREDIT' THEN le.amount ELSE -le.amount END),
    0
  ) AS balance
FROM accounts a
LEFT JOIN ledger_entries le ON le.account_id = a.id
GROUP BY a.id, a.account_number, a.account_name, a.account_type, a.currency, a.status;