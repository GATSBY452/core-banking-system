# Banking Gateway

Spring Boot API Gateway — the secure middleware between the iOS app and the Core Banking Systems.

![Java](https://img.shields.io/badge/Java-21-orange)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.5.14-green)
![Spring Security](https://img.shields.io/badge/Spring_Security-6.x-green)
![Docker](https://img.shields.io/badge/Docker-ready-blue)

---

## What It Does

- Validates every JWT token from the iOS app
- Routes requests to traditional or blockchain CBS
- Generates its own JWT tokens (iOS never sees CBS tokens)
- Applies business rules before forwarding requests
- Provides a single stable API for the iOS app
- Logs every request and response

---

## Quick Start

### With Docker (recommended)
```bash
cd ../
docker-compose up -d
```

### Manual (IntelliJ)
```bash
mvn spring-boot:run
```

Server runs at: `http://localhost:8080`
Health check: `http://localhost:8080/actuator/health`

---

## Project Structure

```
banking-gateway/
└── src/main/java/com/corebanking/gateway/
    ├── config/
    │   ├── SecurityConfig.java     ← JWT filter chain, CORS, public routes
    │   └── AppConfig.java          ← RestTemplate beans, CBS URLs
    ├── controller/
    │   ├── AuthController.java     ← /api/v1/auth/**
    │   ├── AccountController.java  ← /api/v1/accounts/**
    │   └── TransactionController.java ← /api/v1/transactions/**
    ├── model/
    │   ├── request/                ← LoginRequest, RegisterRequest, TransactionRequest
    │   └── response/               ← ApiResponse<T>, AuthResponse
    ├── security/
    │   ├── JwtUtil.java            ← generate and validate tokens
    │   └── JwtFilter.java          ← intercepts every HTTP request
    └── service/
        ├── AuthService.java        ← calls Node.js, generates tokens
        ├── AccountService.java     ← forwards account requests
        ├── TransactionService.java ← forwards transaction requests
        └── TokenStoreService.java  ← manages Node.js CBS tokens
```

---

## How It Works

### Two-Token System

```
iOS App logs in
      │
      ▼
Spring Boot calls Node.js CBS
      │  Node.js verifies credentials → returns Node.js JWT
      │  Spring Boot stores Node.js JWT in TokenStoreService
      │  Spring Boot generates its OWN JWT
      ▼
iOS App receives Spring Boot JWT
      │  uses it on every future request
      │  never knows Node.js exists
      ▼
Future requests:
  iOS → Spring Boot (validates Spring JWT)
           → gets CBS token from TokenStoreService
           → forwards to Node.js with CBS token
```

### Security Filter Chain

Every request passes through:
```
CorsFilter → JwtFilter → AuthorizationFilter → Controller
```

Public routes (no token needed):
```
POST /api/v1/auth/register
POST /api/v1/auth/login
GET  /actuator/health
```

Everything else requires a valid Spring Boot JWT.

---

## API Endpoints

Base URL: `http://localhost:8080/api/v1`

All endpoints mirror the Traditional CBS — Spring Boot forwards to Node.js internally.

### Auth
```
POST /auth/register    → create account (public)
POST /auth/login       → login (public)
GET  /auth/me          → profile (protected)
```

### Accounts (all protected)
```
GET   /accounts
GET   /accounts/:id
GET   /accounts/:id/balance
GET   /accounts/:id/transactions
POST  /accounts
PATCH /accounts/:id/status
```

### Transactions (all protected)
```
POST /transactions/deposit
POST /transactions/withdraw
POST /transactions/transfer
GET  /transactions/:id
POST /transactions/:id/reverse
```

---

## Configuration

### application.yml
```yaml
server:
  port: 8080
  address: 0.0.0.0

cbs:
  traditional:
    base-url: http://traditional-api:3000/api/v1
  blockchain:
    base-url: http://blockchain-api:3001/api/v1

jwt:
  secret: your_gateway_secret_key
  expiration: 86400000
```

### Docker Environment Variables
```
SERVER_PORT=8080
CBS_TRADITIONAL_BASE_URL=http://traditional-api:3000/api/v1
JWT_SECRET=your_secret
JWT_EXPIRATION=86400000
```

---

## Key Dependencies

```xml
spring-boot-starter-web
spring-boot-starter-security
jjwt-api (0.12.6)
lombok
spring-boot-starter-actuator
spring-boot-starter-validation
```
