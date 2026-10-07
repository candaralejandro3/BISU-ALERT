# BISU-Alert Configuration & Setup Guide

## Quick Setup Checklist

- [ ] Clone repository
- [ ] Run `flutter pub get`
- [ ] Configure Firebase
- [ ] Update API base URL
- [ ] Configure hotline numbers
- [ ] Set up backend server
- [ ] Test all features locally
- [ ] Build APK for testing

---

## 1. API Configuration

### Update API Base URL

Edit `lib/data/services/api_service.dart`:

```dart
static const String _baseUrl = 'https://your-backend-domain.com';
```

Replace with your actual backend server address.

---

## 2. Emergency Hotline Configuration

### Update SMS Hotline Numbers

Edit `lib/data/services/sms_alert_service.dart`:

```dart
/// BISU Bilar Campus Security Hotline
static const String campusSecurityHotline = '+639123456789'; // YOUR NUMBER

/// Backup emergency numbers
static const String policeEmergency = '911';
static const String medicalEmergency = '911';
static const String disasterManagement = '09209662687';
```

**Get the actual numbers:**
1. Contact BISU Campus Security office
2. Get Campus Clinic hotline
3. Get MDRRMO (Provincial Disaster Management) contact

---

## 3. Firebase Configuration

### For Android

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Click "Create Project"
   - Name: "BISU-Alert"
   - Region: Southeast Asia

2. **Register Android App**
   - Project Settings → Add Android app
   - Package name: `com.bisu.alert` (or your app id)
   - SHA-1 fingerprint (optional for dev)
   - Download `google-services.json`

3. **Add to Project**
   ```bash
   mkdir -p android/app
   # Copy google-services.json to android/app/
   ```

4. **Enable Services**
   - Cloud Messaging (automatic)
   - Analytics (automatic)
   - Crashlytics (recommended)

### For iOS (if building for iOS)

1. Register iOS app in Firebase Console
2. Download `GoogleService-Info.plist`
3. Open `ios/Runner.xcworkspace` in Xcode
4. Add `GoogleService-Info.plist` to Runner target
5. Update iOS deployment target to 11.0+

---

## 4. Image Picker Permissions

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera is needed to take photos for incident reports</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is needed to select images for incident reports</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Permission needed to save photos</string>
```

---

## 5. Location Permissions

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Add to `android/app/build.gradle.kts`:

```kotlin
android {
    compileSdk 34 // or higher
    defaultConfig {
        targetSdk 34 // or higher
    }
}
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location is needed for campus safety features and incident reporting</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Location is needed for automatic campus check-in and geofencing</string>
```

---

## 6. Accelerometer Permissions

### Android

Permissions are automatic in `AndroidManifest.xml`

### iOS

No additional permissions needed (motion data is always allowed)

---

## 7. Environment Variables (Recommended)

Create `.env` file in project root:

```
API_BASE_URL=https://your-backend-domain.com
FIREBASE_PROJECT_ID=your-firebase-project
CAMPUS_SECURITY_HOTLINE=+639123456789
POLICE_EMERGENCY=911
```

Update `lib/config/app_config.dart`:

```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );
  
  static const String campusSecurityHotline = String.fromEnvironment(
    'CAMPUS_SECURITY_HOTLINE',
    defaultValue: '+639123456789',
  );
}
```

Load with:
```bash
flutter run --dart-define=API_BASE_URL=https://your-backend.com
```

---

## 8. Backend Setup (Node.js Example)

### Project Structure

```
backend/
├── src/
│   ├── api/
│   │   ├── auth.js
│   │   ├── incidents.js
│   │   ├── alerts.js
│   │   └── users.js
│   ├── middleware/
│   │   ├── auth.js
│   │   └── errorHandler.js
│   ├── models/
│   │   ├── User.js
│   │   ├── Incident.js
│   │   └── Alert.js
│   ├── services/
│   │   ├── firebase.js
│   │   └── storage.js
│   ├── config.js
│   └── server.js
├── .env
├── .gitignore
└── package.json
```

### Essential npm Packages

```json
{
  "dependencies": {
    "express": "^4.18.0",
    "cors": "^2.8.5",
    "dotenv": "^16.0.0",
    "jsonwebtoken": "^9.0.0",
    "bcryptjs": "^2.4.3",
    "firebase-admin": "^11.0.0",
    "mongoose": "^7.0.0",
    "multer": "^1.4.5",
    "express-rate-limit": "^6.0.0"
  }
}
```

### Sample Express Server

```javascript
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', require('./src/api/auth'));
app.use('/api/incidents', require('./src/api/incidents'));
app.use('/api/alerts', require('./src/api/alerts'));
app.use('/api/users', require('./src/api/users'));

// Error handler
app.use((err, req, res, next) => {
  res.status(err.statusCode || 500).json({
    success: false,
    message: err.message,
    error: { code: err.code }
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

---

## 9. Database Setup (MongoDB Example)

### Connection String

Add to `.env`:
```
MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/bisu-alert
```

### Schema Examples

**User Schema:**
```javascript
const userSchema = {
  _id: ObjectId,
  email: String,
  passwordHash: String,
  firstName: String,
  lastName: String,
  idNumber: String,
  phone: String,
  deviceToken: String,
  role: String, // student, staff, responder
  createdAt: Date,
  updatedAt: Date
}
```

**Incident Schema:**
```javascript
const incidentSchema = {
  _id: ObjectId,
  userId: ObjectId,
  category: String, // Medical, Fire, Crime, Disaster
  severity: String, // Low, Medium, Critical
  location: String,
  latitude: Number,
  longitude: Number,
  description: String,
  isAnonymous: Boolean,
  status: String, // Reported, Acknowledged, Dispatched, Resolved
  mediaUrls: [String],
  createdAt: Date,
  updatedAt: Date
}
```

---

## 10. Firebase Cloud Messaging Setup

### Server-Side (Send Notifications)

```javascript
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(require('./serviceAccountKey.json')),
});

async function sendCriticalAlert(title, body) {
  const message = {
    notification: { title, body },
    topic: 'campus_emergency',
    android: {
      priority: 'high',
      notification: {
        sound: 'alert_siren',
        priority: 'max',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK'
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'alert_siren.aiff',
          'content-available': 1
        }
      }
    }
  };

  try {
    await admin.messaging().send(message);
    console.log('Message sent successfully');
  } catch (error) {
    console.error('Error sending message:', error);
  }
}
```

---

## 11. Testing Locally

### Start Flutter Development

```bash
# Clean build
flutter clean
flutter pub get

# Run with specific API
flutter run --dart-define=API_BASE_URL=http://localhost:3000

# Run with Firebase emulator
firebase emulators:start
```

### Test API Endpoints

```bash
# Test login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Create test incident
curl -X POST http://localhost:3000/api/incidents/create \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"category":"Medical","severity":"Critical","location":"Test","latitude":9.71888,"longitude":124.10883,"description":"Test incident","isAnonymous":false}'
```

---

## 12. Production Deployment

### Before Going Live

- [ ] Secure all environment variables
- [ ] Enable Firebase Security Rules
- [ ] Set up SSL certificate
- [ ] Configure rate limiting
- [ ] Enable database backups
- [ ] Set up monitoring/logging
- [ ] Test error handling
- [ ] Load testing
- [ ] Security audit
- [ ] GDPR compliance check

### Deploy Backend

```bash
# Using Google Cloud Run (recommended)
gcloud run deploy bisu-alert-backend \
  --source . \
  --region asia-southeast1 \
  --allow-unauthenticated
```

### Build APK for Release

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-production-api.com
```

---

## Support & Troubleshooting

### Common Issues

**Issue: "google-services.json not found"**
- Solution: Ensure file is in `android/app/` directory
- Run: `flutter clean && flutter pub get`

**Issue: API connection timeout**
- Solution: Check backend is running
- Verify API_BASE_URL is correct
- Check network connectivity

**Issue: Push notifications not working**
- Solution: Verify Firebase is initialized
- Check device token in device logs
- Ensure app has notification permissions

**Issue: Location permission denied**
- Solution: Grant permissions in device settings
- Call `GeofencingService().requestLocationPermissions()`

### Debug Commands

```bash
# View device logs
flutter logs

# View Firebase logs
firebase functions:log

# Test connectivity
adb shell ping 8.8.8.8

# Clear app data
adb shell pm clear com.bisu.alert
```

---

## Useful Links

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Console](https://console.firebase.google.com)
- [Express.js Guide](https://expressjs.com)
- [MongoDB Docs](https://docs.mongodb.com)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)

---

## Support Contact

For technical assistance:
- 📧 Email: tech-support@bisu.edu.ph
- 📱 Phone: +639123456789
- 💬 Telegram: @bisualertdev
