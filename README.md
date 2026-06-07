# Core Banking System

A full-stack core banking platform built from scratch — demonstrating how modern fintech companies architect and deliver financial services.

![Architecture](https://img.shields.io/badge/Architecture-Microservices-blue)
![Node.js](https://img.shields.io/badge/Node.js-24.x-green)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.5-green)
![Swift](https://img.shields.io/badge/Swift-5.x-orange)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│               iOS App (Swift/UIKit)                  │
│         Splash · Onboarding · Auth · Dashboard       │
└──────────────────────┬──────────────────────────────┘
                       │ HTTP · Bearer JWT
                       ▼
┌─────────────────────────────────────────────────────┐
│           Spring Boot API Gateway (Java)              │
│       JWT Security · Routing · Business Rules         │
│                    Port 8080                          │
└──────────┬───────────────────────────┬───────────────┘
           │                           │
           ▼                           ▼
┌──────────────────────┐   ┌──────────────────────────┐
│  Traditional CBS      │   │    Blockchain CBS         │
│  Node.js + Express    │   │  Node.js + ethers.js      │
│  Port 3000            │   │  Port 3001                │
└──────────┬────────────┘   └──────────┬───────────────┘
           │                           │
           ▼                           ▼
┌──────────────────────┐   ┌──────────────────────────┐
│  PostgreSQL 16        │   │  Ethereum Smart Contract  │
│  Double-entry ledger  │   │  Bank.sol (Hardhat)       │
└──────────────────────┘   └──────────────────────────┘
```

---

## Projects

| Folder | Description | Tech Stack | Port |
|---|---|---|---|
| [`traditional-api`](./traditional-api) | Core Banking System | Node.js, Express, PostgreSQL | 3000 |
| [`banking-gateway`](./banking-gateway) | API Gateway & Security | Java 21, Spring Boot 3.5 | 8080 |
| [`blockchain-api`](./blockchain-api) | Blockchain CBS | Node.js, Solidity, Hardhat | 3001 |
| [`ios-app`](./ios-app) | Mobile Banking App | Swift 5, UIKit (Programmatic) | — |

---

## Key Features

### Banking
- Double-entry bookkeeping — every transaction creates balanced debit/credit pairs
- Atomic transactions — all-or-nothing with full rollback on failure
- Idempotency — duplicate requests never process twice
- Full audit trail — every action logged permanently
- Account management — savings, current, wallet accounts
- Transaction types — deposit, withdrawal, transfer, reversal

### Security
- Two-layer JWT authentication (Spring Boot + Node.js)
- Passwords hashed with bcrypt (cost factor 12)
- Route-level authorization via Spring Security filter chain
- SQL injection prevention via parameterized queries
- Sensitive data masked in all logs

### Infrastructure
- Docker Compose — entire system starts with one command
- Health checks on all services
- Inter-service communication by container name
- Persistent PostgreSQL volume

### iOS App
- UIKit Programmatic (no Storyboard)
- MVVM architecture
- Full request/response logging
- Onboarding, auth, dashboard with live balance

---

## Quick Start

### Prerequisites
- Docker Desktop
- Xcode 16+ (for iOS app)

### Start All Backend Services

```bash
git clone https://github.com/GATSBY452/core-banking-system.git
cd core-banking-system
docker-compose up -d
```

Services will be available at:
```
Traditional CBS:  http://localhost:3000/api/v1/health
Spring Boot:      http://localhost:8080/actuator/health
PostgreSQL:       localhost:5433
```

### iOS App
1. Open `ios-app/CoreBankingApp.xcodeproj` in Xcode
2. Update `Constants.swift` with your Mac IP:
```swift
static let baseURL = "http://YOUR_MAC_IP:8080/api/v1"
```
3. Press `Cmd+R` to run

---

## API Reference

All requests go through the Spring Boot Gateway on port `8080`.

### Authentication
```
POST /api/v1/auth/register    → create account
POST /api/v1/auth/login       → get JWT token
GET  /api/v1/auth/me          → get profile
```

### Accounts
```
GET   /api/v1/accounts                    → all accounts with balances
GET   /api/v1/accounts/:id/balance        → balance only
GET   /api/v1/accounts/:id/transactions   → transaction history
PATCH /api/v1/accounts/:id/status         → freeze/unfreeze
```

### Transactions
```
POST /api/v1/transactions/deposit     → deposit money
POST /api/v1/transactions/withdraw    → withdraw money
POST /api/v1/transactions/transfer    → transfer to another account
POST /api/v1/transactions/:id/reverse → reverse a transaction
```

---

## Double-Entry Accounting

Every financial event creates minimum 2 ledger entries that always net to zero:

```
Deposit $500:
  DEBIT  Bank Vault        $500  ← cash arrives at bank
  CREDIT Customer Account  $500  ← customer balance goes up
  Net = $0 ✅

Transfer $100 (John → Mary):
  DEBIT  John's Account  $100  ← John's balance goes down
  CREDIT Mary's Account  $100  ← Mary's balance goes up
  Net = $0 ✅
```

---

## Environment Variables

### Traditional API
```env
PORT=3000
DB_HOST=postgres
DB_NAME=core_banking
DB_USER=bankadmin
DB_PASSWORD=bankpass123
JWT_SECRET=your_secret
```

### Spring Boot Gateway
```yaml
cbs.traditional.base-url: http://traditional-api:3000/api/v1
jwt.secret: your_gateway_secret
jwt.expiration: 86400000
```

---

## Documentation

- [PRD — Product Requirements Document](./docs/PRD.md)
- [TRD — Technical Requirements Document](./docs/TRD.md)

---

## Roadmap

- [x] Traditional Core Banking System (Node.js + PostgreSQL)
- [x] Spring Boot API Gateway
- [x] Docker Compose setup
- [x] iOS App — Auth flow
- [x] iOS App — Dashboard
- [ ] Blockchain CBS (Solidity + Hardhat)
- [ ] iOS App — Transfer screen
- [ ] iOS App — Transaction history
- [ ] iOS App — Blockchain toggle
- [ ] Production deployment (HTTPS, cloud)

---

## Built By

**Yusuf Abbas** — June 2026

Learning full-stack fintech engineering from the ground up.
