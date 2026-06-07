# Blockchain Banking API

Core Banking System where the ledger lives on Ethereum.
Same REST interface as the traditional API — the iOS app never needs to change.

![Node.js](https://img.shields.io/badge/Node.js-24.x-green)
![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)
![Hardhat](https://img.shields.io/badge/Hardhat-2.19-yellow)
![Ethers.js](https://img.shields.io/badge/ethers.js-6.x-purple)
![Status](https://img.shields.io/badge/Status-Phase_3_Planned-orange)

---

## What It Does

Instead of PostgreSQL, the ledger lives on the Ethereum blockchain:

```
Traditional CBS:              Blockchain CBS:
────────────────              ──────────────
ledger_entries table   →      Ethereum blockchain
SQL INSERT             →      Smart contract function call
ACID transaction       →      EVM atomic execution
audit_logs table       →      Immutable on-chain events
PostgreSQL             →      Hardhat local node
```

---

## How Double-Entry Works On-Chain

```solidity
// In Bank.sol — both sides update atomically
function transfer(string fromAccount, string toAccount, uint256 amount) {
    balances[fromAccount] -= amount;   // DEBIT sender
    balances[toAccount]   += amount;   // CREDIT receiver
    // EVM guarantees both happen or neither does
    emit DoubleEntry(txId, fromAccount, toAccount, amount);
}
```

The `DoubleEntry` event is emitted permanently — it can never be deleted or altered.

---

## Quick Start

```bash
# Step 1 — Compile the smart contract
npm run compile

# Step 2 — Start local Ethereum node (new terminal)
npm run node:start

# Step 3 — Deploy Bank.sol to local node
npm run deploy

# Step 4 — Start the API
npm run dev
```

API runs at: `http://localhost:3001`

---

## Project Structure

```
blockchain-api/
├── contracts/
│   └── Bank.sol               ← The CBS — written in Solidity
├── artifacts/
│   └── Bank.json              ← Compiled ABI + bytecode
├── scripts/
│   ├── compile.js             ← Compiles Bank.sol using solc
│   └── deploy.js              ← Deploys to local Hardhat node
├── src/
│   ├── services/
│   │   ├── blockchain.service.js  ← ethers.js connection + helpers
│   │   └── customer.service.js    ← off-chain auth (email/password)
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   ├── account.controller.js
│   │   └── transaction.controller.js
│   ├── middleware/
│   │   └── auth.js
│   └── routes/
│       └── index.js
├── .env
└── index.js
```

---

## API Endpoints

Base URL: `http://localhost:3001/api/v1`

Same endpoints as the traditional API — Spring Boot routes to either system.

```
POST /auth/register
POST /auth/login
GET  /accounts
POST /transactions/deposit
POST /transactions/withdraw
POST /transactions/transfer
GET  /admin/chain-info         ← blockchain-specific
GET  /admin/ledger             ← view on-chain double-entry entries
POST /admin/deploy             ← deploy Bank.sol contract
```

---

## Key Differences vs Traditional

| | Traditional | Blockchain |
|---|---|---|
| Ledger storage | PostgreSQL table | Ethereum blockchain |
| Atomicity | DB transaction | EVM execution |
| Audit trail | audit_logs table | Immutable events |
| Balance query | SQL SUM() | Smart contract view |
| Immutability | Mutable (admin can edit) | Immutable forever |

---

## Environment Variables

```env
PORT=3001
BLOCKCHAIN_RPC_URL=http://127.0.0.1:8545
CHAIN_ID=1337
CONTRACT_ADDRESS=              ← filled after npm run deploy
BANK_OWNER_PRIVATE_KEY=0xac0974...   ← Hardhat test account
JWT_SECRET=your_secret
BANK_NAME=MyBlockchainBank
```

---

## Status

**Phase 3 — Planned**

The smart contract `Bank.sol` is written and compiles successfully.
Full API integration is the next development phase.
