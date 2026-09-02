# CivicPulse - Backend API Documentation

Production-grade RESTful backend for **CivicPulse** built with Spring Boot 4.1.1, Java 17, Spring Security with JWT, Spring Data JPA / Hibernate, and PostgreSQL.

---

## 🏛️ System Architecture

```
Client (Web / Mobile)
        │
        ▼
Spring Security & JWT Filter (Bearer Token Authentication)
        │
        ▼
REST Controllers (/api/*)
        │
        ▼
Service Layer (Business Logic, Validation, Authorization & Notifications)
        │
        ▼
Repository Layer (Spring Data JPA / Specifications)
        │
        ▼
PostgreSQL Database (civicpulse_db)
```

---

## ⚙️ Environment Configuration

The backend supports configuration via environment variables or a local `.env` file:

| Variable | Description | Default Value |
| :--- | :--- | :--- |
| `DB_URL` | PostgreSQL JDBC Connection URL | `jdbc:postgresql://localhost:5432/civicpulse_db` |
| `DB_USERNAME` | PostgreSQL Username | `postgres` |
| `DB_PASSWORD` | PostgreSQL Password | `<your_database_password>` |
| `JWT_SECRET` | 256-bit+ HMAC-SHA Key | *(Secure pre-configured key)* |
| `JWT_EXPIRATION`| Token Expiration Time (ms) | `86400000` *(24 hours)* |

---

## 🚀 Running & Testing

### Run All Unit & Integration Tests (59 Tests)
```powershell
.\mvnw.cmd test
```

### Start Local Server
```powershell
.\mvnw.cmd spring-boot:run
```
The server starts on port `8080` (`http://localhost:8080`).

---

## 🔐 Authentication & Roles

Authentication is stateless and uses Bearer JWT tokens in the `Authorization` header:
```http
Authorization: Bearer <your_jwt_token>
```

### Roles & Permissions:
- **`CITIZEN`**: Register/Login, submit issues, view public issues, manage own issues, upload image metadata, post comments, delete own comments, upvote/un-upvote, receive notifications.
- **`OFFICIAL`**: Citizen capabilities + view assigned issues, update issue statuses, manage assignments, create resolutions, perform moderation reviews.
- **`ADMIN`**: Full platform management (territories, departments, categories, statuses, all issues, assignments, resolutions, moderations).

---

## 📋 Comprehensive API Endpoints

### 1. Authentication (`/api/auth`)

#### `POST /api/auth/register` (Public)
Register a new citizen account.
```json
{
  "fullName": "John Doe",
  "email": "john@example.com",
  "password": "Password123!",
  "phoneNumber": "0771234567"
}
```
**Response (`201 Created`)**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "message": "User registered successfully",
  "user": {
    "userId": 1,
    "fullName": "John Doe",
    "email": "john@example.com",
    "phoneNumber": "0771234567",
    "role": "CITIZEN",
    "accountStatus": "ACTIVE",
    "createdAt": "2026-09-01T18:00:00"
  }
}
```

#### `POST /api/auth/login` (Public)
Authenticate with email and password.
```json
{
  "email": "john@example.com",
  "password": "Password123!"
}
```
**Response (`200 OK`)**: Returns JWT token and user details.

---

### 2. Territories (`/api/territories`)

- `GET /api/territories` — List all territories
- `GET /api/territories/{id}` — Get territory by ID
- `POST /api/territories` — Create territory (*Admin*)
  ```json
  {
    "territoryName": "Colombo Municipality",
    "territoryType": "MUNICIPALITY",
    "parentTerritoryId": null,
    "boundaryGeometry": "{\"type\": \"Polygon\", \"coordinates\": [...]}"
  }
  ```
- `PUT /api/territories/{id}` — Update territory (*Admin*)
- `DELETE /api/territories/{id}` — Delete territory (*Admin*)

---

### 3. Departments (`/api/departments`)

- `GET /api/departments?territoryId=` — List departments (optional territory filter)
- `GET /api/departments/{id}` — Get department by ID
- `POST /api/departments` — Create department (*Admin*)
  ```json
  {
    "departmentName": "Road Development Authority",
    "description": "Handles road construction and maintenance",
    "contactNumber": "0112860860",
    "email": "rda@gov.lk",
    "territoryId": 1
  }
  ```
- `PUT /api/departments/{id}` — Update department (*Admin*)
- `DELETE /api/departments/{id}` — Delete department (*Admin*)

---

### 4. Issue Categories (`/api/categories`)

- `GET /api/categories` — List all categories
- `GET /api/categories/{id}` — Get category by ID
- `POST /api/categories` — Create category (*Admin*)
  ```json
  {
    "categoryName": "Roads & Infrastructure",
    "description": "Potholes, broken roads, damaged bridges"
  }
  ```
- `PUT /api/categories/{id}` — Update category (*Admin*)
- `DELETE /api/categories/{id}` — Delete category (*Admin*)

---

### 5. Issue Statuses (`/api/statuses`)

- `GET /api/statuses` — List all statuses
- `GET /api/statuses/{id}` — Get status by ID
- `POST /api/statuses` — Create status (*Admin*)
  ```json
  {
    "statusName": "IN_PROGRESS",
    "description": "Issue is currently being resolved by assigned staff"
  }
  ```
- `PUT /api/statuses/{id}` — Update status (*Admin*)
- `DELETE /api/statuses/{id}` — Delete status (*Admin*)

---

### 6. Issues (`/api/issues`)

- `POST /api/issues` — Submit a new issue
  ```json
  {
    "title": "Large pothole at Galle Road crossing",
    "description": "Deep pothole causing vehicle damage and traffic slowdown",
    "latitude": 6.9271,
    "longitude": 79.8612,
    "locationPoint": "Galle Road, Bambalapitiya",
    "visibility": "PUBLIC",
    "severity": "HIGH",
    "isTransitReport": false,
    "categoryId": 1,
    "territoryId": 1
  }
  ```
  **Response (`201 Created`)**:
  ```json
  {
    "issueId": 101,
    "title": "Large pothole at Galle Road crossing",
    "description": "Deep pothole causing vehicle damage and traffic slowdown",
    "latitude": 6.9271,
    "longitude": 79.8612,
    "locationPoint": "Galle Road, Bambalapitiya",
    "visibility": "PUBLIC",
    "severity": "HIGH",
    "isTransitReport": false,
    "createdAt": "2026-09-01T20:00:00",
    "userId": 1,
    "userFullName": "John Doe",
    "categoryId": 1,
    "categoryName": "Roads & Infrastructure",
    "statusId": 1,
    "statusName": "REPORTED",
    "upvoteCount": 0,
    "commentCount": 0
  }
  ```
- `GET /api/issues?categoryId=&statusId=&territoryId=&severity=&departmentId=&userId=&page=0&size=20&sortBy=createdAt&sortDir=desc` — Paginated and filtered issue listing.
- `GET /api/issues/{id}` — Get issue details including upvote and comment counters.
- `PUT /api/issues/{id}` — Update issue (*Reporter* or *Staff*).
- `DELETE /api/issues/{id}` — Delete issue (*Reporter* or *Admin*).

---

### 7. Issue Images (`/api/issues/{issueId}/images`)

- `POST /api/issues/{issueId}/images` — Attach image metadata to an issue
  ```json
  {
    "imageUrl": "https://storage.civicpulse.org/issues/img-101-1.jpg",
    "originalFilename": "pothole-photo.jpg",
    "aiSafetyScore": 0.98,
    "aiRelevanceScore": 0.95,
    "isAnonymized": false
  }
  ```
- `GET /api/issues/{issueId}/images` — List images for an issue
- `DELETE /api/issues/{issueId}/images/{imageId}` — Delete image

---

### 8. Comments (`/api/issues/{issueId}/comments`, `/api/comments/{commentId}`)

- `POST /api/issues/{issueId}/comments` — Add a comment (triggers notification for issue owner)
  ```json
  {
    "commentText": "I passed by this morning, it has gotten larger due to rain."
  }
  ```
- `GET /api/issues/{issueId}/comments` — List all non-deleted comments for issue
- `DELETE /api/comments/{commentId}` — Soft-delete a comment (*Author* or *Staff*)

---

### 9. Upvotes (`/api/issues/{issueId}/upvotes`)

- `POST /api/issues/{issueId}/upvotes` — Upvote an issue (Unique constraint prevents duplicate votes per user)
  **Response (`201 Created`)**:
  ```json
  {
    "message": "Upvote recorded successfully",
    "issueId": 101,
    "totalUpvotes": 12
  }
  ```
- `DELETE /api/issues/{issueId}/upvotes` — Remove upvote
- `GET /api/issues/{issueId}/upvotes/count` — Get upvote count
- `GET /api/issues/{issueId}/upvotes/me` — Check if current user has upvoted

---

### 10. Moderation (`/api/issues/{issueId}/moderation`, `/api/moderation/{moderationId}`)

*Requires `OFFICIAL` or `ADMIN` role.*
- `GET /api/issues/{issueId}/moderation` — Get AI/manual moderation record
- `POST /api/issues/{issueId}/moderation` — Create or update issue moderation status
  ```json
  {
    "toxicityScore": 0.02,
    "spamScore": 0.05,
    "privacyDetected": false,
    "textModerationStatus": "APPROVED"
  }
  ```
- `PUT /api/moderation/{moderationId}` — Update moderation by ID

---

### 11. Issue Assignments (`/api/issues/{issueId}/assignments`, `/api/assignments/{assignmentId}`)

*Requires `OFFICIAL` or `ADMIN` role.*
- `POST /api/issues/{issueId}/assignments` — Assign issue to department & official (transitions issue status to `ASSIGNED` and sends notifications)
  ```json
  {
    "departmentId": 1,
    "assignedUserId": 2
  }
  ```
- `GET /api/issues/{issueId}/assignments` — Get assignment history
- `PUT /api/assignments/{assignmentId}` — Update assignment / mark completed
- `DELETE /api/assignments/{assignmentId}` — Remove assignment

---

### 12. Resolutions (`/api/issues/{issueId}/resolution`, `/api/resolutions/{resolutionId}`)

*Requires `OFFICIAL` or `ADMIN` role.*
- `POST /api/issues/{issueId}/resolution` — Resolve issue (transitions issue status to `RESOLVED` and sends notification to reporter)
  ```json
  {
    "resolutionDescription": "Road maintenance crew filled and resurfaced the pothole with asphalt.",
    "resolutionImage": "https://storage.civicpulse.org/resolutions/res-101.jpg"
  }
  ```
- `GET /api/issues/{issueId}/resolution` — Get resolution details
- `PUT /api/resolutions/{resolutionId}` — Update resolution details

---

### 13. Notifications (`/api/notifications`)

- `GET /api/notifications` — Get all notifications for current user
- `GET /api/notifications/unread` — Get unread notifications
- `PUT /api/notifications/{id}/read` — Mark notification as read
- `PUT /api/notifications/read-all` — Mark all notifications as read

---

## 🛡️ Centralized Error Responses

All error responses adhere to a consistent JSON format:
```json
{
  "timestamp": "2026-09-01T20:15:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed for one or more fields",
  "path": "/api/issues",
  "validationErrors": {
    "title": "Title is required",
    "categoryId": "Category ID is required"
  }
}
```
