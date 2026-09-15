# JualBeli Backend

Backend API for the JualBeli Flutter application.

## Tech Stack

* Dart
* Shelf
* Shelf Router
* Microsoft SQL Server
* `mssql`
* BCrypt password hashing

## Database

The backend connects to SQL Server using:

```text
Host:     127.0.0.1
Port:     1433
Database: JualBeliDb
```

The SQL Server connection uses encryption with `trustServerCertificate` enabled for local development.

## Running the Backend

From the `jualbeli_backend` directory:

```powershell
dart pub get
dart run
```

The backend runs on:

```text
https://jualbeli-v2-aldariaski-api.vercel.app
```

You should see:

```text
Connecting to SQL Server...
Host: 127.0.0.1
Port: 1433
Database: JualBeliDb
========== SQL SERVER CONNECTED ==========
Database connection successful!
==========================================
JualBeli backend running on http://0.0.0.0:8080
```

---

# Authentication API

The backend currently provides:

| Method | Endpoint         | Description            |
| ------ | ---------------- | ---------------------- |
| `POST` | `/auth/register` | Register a new user    |
| `POST` | `/auth/login`    | Login an existing user |

---

## Register

### Endpoint

```text
POST https://jualbeli-v2-aldariaski-api.vercel.app/auth/register
```

### Request

PowerShell:

```powershell
Invoke-RestMethod `
  -Uri "https://jualbeli-v2-aldariaski-api.vercel.appauth/register" `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"name":"Test User","email":"test@example.com","password":"password123"}'
```

### Expected Response

```text
message                  user
-------                  ----
Registration successful. @{id=1; name=Test User; email=test@example.com; createdAt=2026-08-10T04:51:11.996730Z}
```

The user is inserted into the `Users` table in `JualBeliDb`.

Passwords are hashed using BCrypt before being stored in the database.

---

## Login

### Endpoint

```text
POST https://jualbeli-v2-aldariaski-api.vercel.app/auth/login
```

### Request

PowerShell:

```powershell
Invoke-RestMethod `
  -Uri "https://jualbeli-v2-aldariaski-api.vercel.appauth/login" `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"email":"test@example.com","password":"password123"}'
```

### Expected Response

```text
message           user
-------           ----
Login successful. @{id=1; name=Test User; email=test@example.com}
```

The backend:

1. Finds the user by email.
2. Retrieves the stored BCrypt password hash.
3. Verifies the supplied password.
4. Returns the user when authentication succeeds.

---

## Authentication Flow

### Registration

```text
Client
  │
  │ POST /auth/register
  ▼
AuthRoutes
  │
  ▼
AuthService
  │
  ├── Validate input
  ├── Check existing email
  └── BCrypt hash password
  │
  ▼
UserRepository
  │
  ▼
SQL Server
  │
  ▼
Users table
```

### Login

```text
Client
  │
  │ POST /auth/login
  ▼
AuthRoutes
  │
  ▼
AuthService
  │
  ├── Find user by email
  └── Verify BCrypt password
  │
  ▼
UserRepository
  │
  ▼
SQL Server
  │
  ▼
Login successful
```

---

## Current Authentication Test

The backend has been successfully tested locally.

### Registration

```text
Registration successful.
User ID: 1
Name: Test User
Email: test@example.com
Password: password123
```

### Login

```text
Login successful.
User ID: 1
Name: Test User
Email: test@example.com
Password: password123
```

This confirms that:

* SQL Server connection works.
* The `JualBeliDb` database is accessible.
* User registration works.
* Users are inserted into SQL Server.
* BCrypt password hashing works.
* User login works.
* BCrypt password verification works.
* The Shelf HTTP API works.

---

## Development Notes

The SQL Server connection currently uses:

```dart
encrypt: true,
trustServerCertificate: true,
```

This is intended for the local development SQL Server environment using its self-signed certificate.

For production, a properly trusted SQL Server certificate should be used instead of relying on `trustServerCertificate`.

## Project Status

### Backend

* [x] SQL Server connection
* [x] Database configuration
* [x] User model
* [x] User repository
* [x] BCrypt password hashing
* [x] User registration API
* [x] User login API
* [x] Registration API tested
* [x] Login API tested
* [ ] JWT/session authentication
* [ ] Protected routes
* [ ] Product API
* [ ] Cart API
* [ ] Checkout API

### Flutter

* [x] Project setup
* [x] Splash screen
* [x] Login UI
* [x] Register UI
* [x] Home UI
* [x] Connect Login UI to backend
* [x] Connect Register UI to backend
* [ ] Product list
* [ ] Product details
* [ ] Cart
* [ ] Checkout
* [ ] Profile
