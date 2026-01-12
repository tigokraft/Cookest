# Secure Authentication API

A production-ready, highly secure authentication API built with Rust, Actix-web, and SeaORM.

## Security Features

| Feature | Implementation |
|---------|----------------|
| Password Hashing | **Argon2id** with OWASP-recommended parameters (19 MiB memory, 2 iterations) |
| Token Auth | **JWT** with short-lived access tokens (15 min) + refresh token rotation |
| Refresh Tokens | **HttpOnly cookies** with Secure, SameSite=Strict flags |
| Rate Limiting | Per-endpoint throttling (10 req/min for auth routes) |
| Account Lockout | Locks after 5 failed attempts for 15 minutes |
| Input Validation | Email format, password strength (uppercase, lowercase, digit, special char) |
| Error Handling | Generic messages to prevent enumeration attacks |

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/register` | POST | Create new user account |
| `/api/auth/login` | POST | Authenticate and get tokens |
| `/api/auth/refresh` | POST | Refresh access token (uses cookie) |
| `/api/auth/logout` | POST | Invalidate refresh token |
| `/health` | GET | Health check |

## Quick Start

### 1. Prerequisites

- Rust 1.70+
- PostgreSQL 13+

### 2. Setup Database

```bash
# Create database
createdb auth_db
```

### 3. Configure Environment

```bash
cp .env.example .env
# Edit .env with your database credentials and a secure JWT secret
# Generate JWT secret: openssl rand -base64 64
```

### 4. Run

```bash
cargo run
```

## Usage Examples

### Register

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "SecurePass123!"}'
```

### Login

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{"email": "user@example.com", "password": "SecurePass123!"}'
```

### Refresh Token

```bash
curl -X POST http://localhost:8080/api/auth/refresh \
  -b cookies.txt \
  -c cookies.txt
```

## Project Structure

```
src/
├── main.rs           # Server entry point
├── config.rs         # Environment configuration
├── db.rs             # Database connection
├── errors.rs         # Error types
├── entity/           # SeaORM entities
│   └── user.rs
├── handlers/         # HTTP handlers
│   └── auth.rs
├── middleware/       # Actix middleware
│   ├── auth.rs       # JWT validation
│   └── rate_limit.rs
├── services/         # Business logic
│   ├── auth.rs       # Authentication
│   └── token.rs      # JWT management
└── validation/       # Input validation
    └── auth.rs
```

## License

MIT
