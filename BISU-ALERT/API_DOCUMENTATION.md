# BISU-Alert Backend API Documentation

## Base URL
```
https://api.bisu-alert.example.com
```

**TODO:** Replace with your actual backend domain

---

## Authentication

All endpoints (except auth endpoints) require Bearer token authentication:

```
Authorization: Bearer <token>
```

---

## Endpoints

### Authentication

#### POST `/api/auth/login`
User login

**Request:**
```json
{
  "email": "student@bisu.edu.ph",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": "user-123",
      "email": "student@bisu.edu.ph",
      "firstName": "John",
      "lastName": "Doe",
      "role": "student"
    }
  }
}
```

#### POST `/api/auth/register`
User registration

**Request:**
```json
{
  "email": "student@bisu.edu.ph",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe",
  "idNumber": "20-12345"
}
```

**Response:** Same as login

#### POST `/api/auth/logout`
User logout (requires token)

---

### Incidents

#### POST `/api/incidents/create`
Create new incident report

**Request:**
```json
{
  "category": "Medical",
  "severity": "Critical",
  "location": "CEA Building",
  "latitude": 9.71888,
  "longitude": 124.10883,
  "description": "Student collapsed near chemistry lab",
  "isAnonymous": false
}
```

**Response:**
```json
{
  "success": true,
  "message": "Incident created successfully",
  "data": {
    "id": "incident-123",
    "category": "Medical",
    "severity": "Critical",
    "location": "CEA Building",
    "latitude": 9.71888,
    "longitude": 124.10883,
    "description": "Student collapsed near chemistry lab",
    "isAnonymous": false,
    "status": "Reported",
    "createdAt": "2026-09-01T10:30:00Z",
    "updatedAt": null,
    "mediaUrls": []
  }
}
```

#### GET `/api/incidents/:id`
Get incident details

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "incident-123",
    "category": "Medical",
    "severity": "Critical",
    "location": "CEA Building",
    "latitude": 9.71888,
    "longitude": 124.10883,
    "description": "Student collapsed near chemistry lab",
    "isAnonymous": false,
    "status": "Dispatched",
    "createdAt": "2026-09-01T10:30:00Z",
    "updatedAt": "2026-09-01T10:35:00Z",
    "mediaUrls": ["https://storage.example.com/incident-123-photo1.jpg"]
  }
}
```

#### GET `/api/incidents/:id/status`
Get incident status with timeline

**Response:**
```json
{
  "success": true,
  "data": {
    "incidentId": "incident-123",
    "status": "Dispatched",
    "message": "Emergency responders on the way",
    "timestamp": "2026-09-01T10:35:00Z",
    "updates": [
      {
        "status": "Reported",
        "description": "Incident reported by campus community",
        "timestamp": "2026-09-01T10:30:00Z"
      },
      {
        "status": "Acknowledged",
        "description": "Campus security acknowledged the report",
        "timestamp": "2026-09-01T10:31:00Z"
      },
      {
        "status": "Dispatched",
        "description": "Emergency responders dispatched to location",
        "timestamp": "2026-09-01T10:35:00Z"
      }
    ]
  }
}
```

#### GET `/api/incidents/user/all`
Get all incidents reported by user

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "incident-123",
      "category": "Medical",
      "severity": "Critical",
      "status": "Resolved",
      "createdAt": "2026-09-01T10:30:00Z"
    }
  ]
}
```

#### GET `/api/incidents/active`
Get all active incidents on campus

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "incident-456",
      "category": "Fire",
      "severity": "Critical",
      "location": "Gymnasium",
      "latitude": 9.71900,
      "longitude": 124.10890,
      "status": "Dispatched",
      "createdAt": "2026-09-01T09:15:00Z"
    }
  ]
}
```

#### POST `/api/incidents/:id/media`
Upload media for incident

**Request:** multipart/form-data
- Field name: `file`
- Content-Type: `image/jpeg`, `image/png`, `video/mp4`

**Response:**
```json
{
  "success": true,
  "data": {
    "url": "https://storage.example.com/incident-123-photo1.jpg",
    "mediaId": "media-456",
    "uploadedAt": "2026-09-01T10:36:00Z"
  }
}
```

#### PUT `/api/incidents/:id/resolve`
Mark incident as resolved

**Request:**
```json
{}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "incident-123",
    "status": "Resolved",
    "updatedAt": "2026-09-01T11:00:00Z"
  }
}
```

---

### Alerts

#### GET `/api/alerts/list`
Get feed of active alerts/announcements

**Query Parameters:**
- `limit`: Number of alerts (default: 20)
- `offset`: Pagination offset (default: 0)
- `category`: Filter by category (optional)

**Response:**
```json
{
  "success": true,
  "data": {
    "alerts": [
      {
        "id": "alert-789",
        "title": "EARTHQUAKE DRILL",
        "message": "Campus-wide earthquake drill at 2:00 PM",
        "priority": "high",
        "category": "Disaster",
        "createdAt": "2026-09-01T08:00:00Z"
      }
    ],
    "total": 45,
    "limit": 20,
    "offset": 0
  }
}
```

#### GET `/api/alerts/:id`
Get specific alert details

---

### Emergency Contacts

#### GET `/api/contacts/list`
Get emergency contacts directory

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "contact-1",
      "name": "Campus Security",
      "phone": "+639123456789",
      "email": "security@bisu.edu.ph",
      "location": "Main Gate",
      "category": "Security"
    },
    {
      "id": "contact-2",
      "name": "Campus Clinic",
      "phone": "+639129876543",
      "email": "clinic@bisu.edu.ph",
      "location": "Health Center",
      "category": "Medical"
    }
  ]
}
```

---

### User Profile

#### GET `/api/users/me`
Get current user profile (requires token)

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "user-123",
    "email": "student@bisu.edu.ph",
    "firstName": "John",
    "lastName": "Doe",
    "idNumber": "20-12345",
    "phone": "+639123456789",
    "deviceToken": "fcm-token-xyz...",
    "role": "student"
  }
}
```

#### PUT `/api/users/me`
Update user profile

**Request:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+639123456789",
  "deviceToken": "fcm-token-xyz..."
}
```

---

## Error Responses

All errors follow this format:

```json
{
  "success": false,
  "message": "Error description",
  "error": {
    "code": "ERROR_CODE",
    "details": "Additional error details"
  }
}
```

### Common Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Server Error

### Common Error Codes
- `INVALID_CREDENTIALS` - Login failed
- `TOKEN_EXPIRED` - JWT token expired
- `MISSING_REQUIRED_FIELD` - Required field missing
- `INVALID_LOCATION` - Location outside campus
- `FILE_TOO_LARGE` - Uploaded file exceeds 10MB

---

## Rate Limiting

- API requests are rate limited to 100 requests per minute per user
- Rate limit headers included in responses:
  - `X-RateLimit-Limit`
  - `X-RateLimit-Remaining`
  - `X-RateLimit-Reset`

---

## Implementation Notes

### Backend Technologies (Recommended)
- **Node.js/Express** or **Python/Django** for REST API
- **Firebase Admin SDK** for push notifications
- **PostgreSQL** or **MongoDB** for data storage
- **Redis** for caching and rate limiting
- **AWS S3** or **Firebase Storage** for media uploads

### Security Considerations
- ✅ Use HTTPS only
- ✅ Validate all input data
- ✅ Implement CORS properly
- ✅ Use JWT with expiration
- ✅ Hash passwords securely
- ✅ Validate file uploads
- ✅ Implement rate limiting
- ✅ Log all API access

### Database Schema (Example)

**users**
- id, email, password_hash, first_name, last_name, id_number, phone, device_token, role, created_at, updated_at

**incidents**
- id, user_id, category, severity, location, latitude, longitude, description, is_anonymous, status, created_at, updated_at

**incident_status_updates**
- id, incident_id, status, description, timestamp

**incident_media**
- id, incident_id, media_url, media_type, uploaded_at

**alerts**
- id, title, message, priority, category, created_at, expires_at

**emergency_contacts**
- id, name, phone, email, location, category

---

## Testing the API

### Using Postman
1. Import the provided Postman collection
2. Set `base_url` variable to your backend URL
3. Use "Login" endpoint first to get token
4. Add token to "Authorization" tab (Bearer Token)
5. Test endpoints in order

### Using cURL
```bash
# Login
curl -X POST https://api.bisu-alert.example.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"student@bisu.edu.ph","password":"password123"}'

# Create incident (with token)
curl -X POST https://api.bisu-alert.example.com/api/incidents/create \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"category":"Medical","severity":"Critical","location":"CEA","latitude":9.71888,"longitude":124.10883,"description":"Test","isAnonymous":false}'
```

---

## Next Steps
1. Implement API endpoints in your backend
2. Set up database schema
3. Configure Firebase Admin SDK
4. Deploy to production
5. Update `_baseUrl` in `lib/data/services/api_service.dart`
6. Test all endpoints thoroughly
