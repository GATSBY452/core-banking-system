# Traditional Banking API

The Core Banking System — built with Node.js, Express and PostgreSQL.
Handles all financial operations with a double-entry ledger engine.

![Node.js](https://img.shields.io/badge/Node.js-24.x-green)
![Express](https://img.shields.io/badge/Express-4.18-lightgrey)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)
![Docker](https://img.shields.io/badge/Docker-ready-blue)

---

## What It Does

- Customer registration and JWT authentication
- Account creation and management (savings, current, wallet)
- Deposit, withdrawal, transfer, reversal
- Double-entry ledger — every transaction creates 2 balanced entries
- Full audit trail — every action logged permanently
- Idempotency — duplicate requests never process twice

---

## Quick Start

### With Docker (recommended)
```bash
cd ../
docker-compose up -d
```

### Manual
```bash
# Create database
psql -U postgres -c "CREATE DATABASE core_banking;"
psql -U postgres -d core_banking -f src/db/schema.sql

# Install and run
npm install
npm run dev
```

Server runs at: `http://localhost:3000`

---

## Project Structure

```
traditional-api/
├── src/
│   ├── controllers/
│   │   ├── auth.controller.js         ← register, login, profile
│   │   ├── account.controller.js      ← create, list, balance, freeze
│   │   └── transaction.controller.js  ← deposit, withdraw, transfer, reverse
│   ├── db/
│   │   ├── index.js                   ← PostgreSQL connection pool
│   │   └── schema.sql                 ← all table definitions
│   ├── engines/
│   │   └── ledger.js                  ← THE HEART: double-entry engine
│   ├── middleware/
│   │   └── auth.js                    ← JWT verification
│   ├── models/
│   │   ├── customer.js                ← customer DB queries
│   │   └── account.js                 ← account DB queries
│   └── routes/
│       └── index.js                   ← all route definitions
├── .env
├── index.js                           ← server entry point
└── package.json
```

---

## API Endpoints

Base URL: `http://localhost:3000/api/v1`

### Auth
```
POST /auth/register    → create customer + savings account
POST /auth/login       → login, get JWT token
GET  /auth/me          → get profile (protected)
```

### Accounts
```
POST  /accounts                      → create additional account
GET   /accounts                      → all accounts with live balances
GET   /accounts/:id                  → single account
GET   /accounts/:id/balance          → balance only
GET   /accounts/:id/transactions     → transaction history
PATCH /accounts/:id/status           → freeze/unfreeze
```

### Transactions
```
POST /transactions/deposit       → deposit money
POST /transactions/withdraw      → withdraw money
POST /transactions/transfer      → transfer by account number
GET  /transactions/:id           → get transaction + ledger entries
POST /transactions/:id/reverse   → reverse a transaction
```

---

## Double-Entry Engine

The `ledger.js` engine is the heart of the system. Every operation:

1. Checks idempotency key — prevents duplicate processing
2. Validates account exists and is active
3. Opens a PostgreSQL transaction (`BEGIN`)
4. Creates a parent transaction record
5. Creates a DEBIT entry on one account
6. Creates a CREDIT entry on another account
7. `COMMIT` — both entries saved atomically
8. Returns new balance (calculated from ledger, never stored)

If anything fails between steps 3 and 7 → `ROLLBACK` → nothing saved.

---

## Database Tables

| Table | Purpose |
|---|---|
| `customers` | KYC data and login credentials |
| `accounts` | Customer bank accounts |
| `system_accounts` | Bank internal accounts (vault, fees, revenue) |
| `transactions` | Parent record for every financial event |
| `ledger_entries` | Every debit and credit — the source of truth |
| `audit_logs` | Permanent action history |
| `refresh_tokens` | Auth token management |

---

## Environment Variables

```env
PORT=3000
NODE_ENV=development
DB_HOST=localhost
DB_PORT=5432
DB_NAME=core_banking
DB_USER=bankadmin
DB_PASSWORD=bankpass123
JWT_SECRET=your_secret_here
JWT_EXPIRES_IN=24h
```

---

## Critical Rules

1. Balance is NEVER stored — always calculated from `ledger_entries`
2. Every transaction is atomic — `BEGIN/COMMIT/ROLLBACK`
3. Every action is logged in `audit_logs`
4. Idempotency keys prevent duplicate processing
5. Passwords hashed with bcrypt (cost factor 12)
6. All endpoints require JWT except register and login
