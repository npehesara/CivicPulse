# CivicPulse - Backend Authentication Module

Production-quality User Authentication module for the **CivicPulse** Spring Boot backend, providing stateless JWT-based authentication, role-based authorization, BCrypt password hashing, Jakarta Bean Validation, and centralized exception handling.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: Spring Boot 4.1.1 (Java 17)
- **Security**: Spring Security & JJWT (0.12.6)
- **Persistence**: Spring Data JPA / Hibernate ORM
- **Database**: PostgreSQL 18.4 (`civicpulse_db`)
- **Validation**: Jakarta Bean Validation (`spring-boot-starter-validation`)

---

## ⚙️ Environment Configuration

The backend supports configuration through environment variables or `.env` files with sensible fallbacks for local development:

| Variable | Description | Default Value |
| :--- | :--- | :--- |
| `DB_URL` | PostgreSQL JDBC connection URL | `jdbc:postgresql://localhost:5432/civicpulse_db` |
| `DB_USERNAME` | PostgreSQL username | `postgres` |
| `DB_PASSWORD` | PostgreSQL password | `12345678` |
| `JWT_SECRET` | 256-bit+ Base64 or plain secret key | *(Preconfigured 256-bit key)* |
| `JWT_EXPIRATION`| Token expiration time in milliseconds | `86400000` *(24 hours)* |

> [!NOTE]
> `.env` is automatically ignored by `.gitignore` to prevent leaking credentials.

---

## 🚀 Running the Application

### 1. Build and Run Tests
```powershell
.\mvnw.cmd test
```

### 2. Start Application Locally
```powershell
.\mvnw.cmd spring-boot:run
```
The server starts on port `8080` (e.g. `http://localhost:8080`).

---

## 🔒 Authentication API Endpoints

Base URL: `/api/auth`

### 1. User Registration

Creates a new user account with default role `CITIZEN` and status `ACTIVE`. Hashes the password using BCrypt and returns an issued JWT token.

- **Method**: `POST`
- **Endpoint**: `/api/auth/register`
- **Headers**: `Content-Type: application/json`

#### Request Body
```json
{
  "fullName": "John Doe",
  "email": "john@example.com",
  "password": "Password123!",
  "phoneNumber": "0771234567"
}
```

#### Success Response (`201 Created`)
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiQ0lUSVpFTiIsInVzZXJJZCI6MSwiZnVsbE5hbWUiOiJKb2huIERvZSIsInN1YiI6ImpvaG5AZXhhbXBsZS5jb20iLCJpYXQiOjE3NDAwMDAwMDAsImV4cCI6MTc0MDA4NjQwMH0...",
  "message": "User registered successfully",
  "user": {
    "userId": 1,
    "fullName": "John Doe",
    "email": "john@example.com",
    "phoneNumber": "0771234567",
    "profileImage": null,
    "role": "CITIZEN",
    "accountStatus": "ACTIVE",
    "createdAt": "2026-09-01T18:23:00"
  }
}
```

#### Conflict Response (`409 Conflict`)
When email is already registered:
```json
{
  "timestamp": "2026-09-01T18:23:05",
  "status": 409,
  "error": "Conflict",
  "message": "Email is already registered: john@example.com",
  "path": "/api/auth/register"
}
```

---

### 2. User Login

Authenticates user credentials, verifies active status, and returns a fresh JWT token.

- **Method**: `POST`
- **Endpoint**: `/api/auth/login`
- **Headers**: `Content-Type: application/json`

#### Request Body
```json
{
  "email": "john@example.com",
  "password": "Password123!"
}
```

#### Success Response (`200 OK`)
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "message": "Login successful",
  "user": {
    "userId": 1,
    "fullName": "John Doe",
    "email": "john@example.com",
    "phoneNumber": "0771234567",
    "profileImage": null,
    "role": "CITIZEN",
    "accountStatus": "ACTIVE",
    "createdAt": "2026-09-01T18:23:00"
  }
}
```

#### Invalid Credentials (`401 Unauthorized`)
```json
{
  "timestamp": "2026-09-01T18:23:10",
  "status": 401,
  "error": "Unauthorized",
  "message": "Invalid email or password",
  "path": "/api/auth/login"
}
```

#### Inactive/Suspended Account (`403 Forbidden`)
```json
{
  "timestamp": "2026-09-01T18:23:15",
  "status": 403,
  "error": "Forbidden",
  "message": "Account is suspended. Please contact support.",
  "path": "/api/auth/login"
}
```

---

### 3. Validation Errors (`400 Bad Request`)

When request constraints fail (e.g. missing fields, invalid email format, short password):
```json
{
  "timestamp": "2026-09-01T18:23:20",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed for one or more fields",
  "path": "/api/auth/register",
  "validationErrors": {
    "email": "Invalid email address format",
    "password": "Password must be at least 6 characters long",
    "fullName": "Full name is required"
  }
}
```

---

## 🛡️ Accessing Protected Endpoints

To access endpoints requiring authentication, supply the JWT in the `Authorization` header:

```http
Authorization: Bearer <your_jwt_token>
```
