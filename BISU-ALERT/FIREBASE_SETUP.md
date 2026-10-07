# Firebase Setup Guide for BISU-Alert

## Prerequisites
- Firebase Project created at [console.firebase.google.com](https://console.firebase.google.com)
- Android app registered in Firebase Console
- iOS app registered in Firebase Console (if building for iOS)

## Step 1: Android Configuration

### 1.1 Download google-services.json
1. Go to Firebase Console → Your Project
2. Click "Project Settings" (⚙️ icon)
3. Under "Your apps", select your Android app
4. Click "Download google-services.json"
5. Save to `android/app/google-services.json`

### 1.2 Add Google Play Services Plugin
The app already has Firebase dependencies in pubspec.yaml:
```yaml
firebase_core: ^3.0.0
firebase_messaging: ^15.0.0
```

### 1.3 Android-Specific Configuration
No additional changes needed - flutter automatically integrates google-services.json

## Step 2: iOS Configuration (if needed)

### 2.1 Download GoogleService-Info.plist
1. Firebase Console → Your Project → Project Settings
2. Select iOS app
3. Click "Download GoogleService-Info.plist"
4. Open iOS project: `cd ios && open Runner.xcworkspace`
5. Right-click "Runner" → Add Files
6. Select GoogleService-Info.plist
7. Check "Copy items if needed" and select Runner target
8. Save

### 2.2 Update iOS Deployment Target
1. In Xcode: Runner → Targets → Runner
2. Set Minimum Deployment to iOS 11.0+
3. Do same for Pods target

## Step 3: Enable Services

### In Firebase Console:
1. **Cloud Messaging**: Already enabled by default
2. **Authentication** (optional):
   - Enable Email/Password if using custom auth
   - Or enable Anonymous auth for quick testing

3. **Firestore Database** (optional):
   - Create collection for incidents: `incidents`
   - Create collection for alerts: `alerts`
   - Set security rules appropriately

## Step 4: Test Firebase Connection

In `lib/main.dart`, the app will attempt to initialize Firebase on startup:
```dart
await PushNotificationService().initialize();
```

To verify it's working:
1. Run the app
2. Check device logs: `flutter logs`
3. Look for: "Firebase initialized successfully"

## Step 5: Configure Push Notification Topics

### Create Topics for Campus-Wide Alerts
Topics allow you to send notifications to groups of devices:

**Recommended topics:**
- `campus_emergency` - Immediate danger alerts
- `campus_weather` - Weather warnings
- `campus_announcements` - General campus news
- `building_xyz` - Building-specific alerts (replace xyz with building name)

### Subscribe Users to Topics
Already implemented in `PushNotificationService`:
```dart
await service.subscribeToTopic('campus_emergency');
```

## Step 6: Send Test Notification (Firebase Console)

1. Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Title: "Test Alert"
4. Body: "Testing BISU-Alert notifications"
5. Target: Select "App" → Choose Android app
6. Schedule: Send now
7. Review and publish

## Step 7: Send Programmatic Messages (Backend)

Use Firebase Admin SDK to send notifications:

**Example (Node.js backend):**
```javascript
const admin = require('firebase-admin');

async function sendAlert(title, body, topic = 'campus_emergency') {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    topic: topic,
  };

  try {
    await admin.messaging().send(message);
    console.log('Message sent successfully');
  } catch (error) {
    console.error('Error sending message:', error);
  }
}

// Send emergency alert
sendAlert('EARTHQUAKE DRILL', 'Proceed to evacuation zone immediately', 'campus_emergency');
```

## Troubleshooting

### App Not Receiving Notifications
- Check Firebase Console → Cloud Messaging → Notifications
- Verify device token is registered
- Check app permissions in device settings
- Ensure app is subscribed to correct topic

### Issues with google-services.json
- Verify file is in correct location: `android/app/`
- File name must be exactly `google-services.json` (case-sensitive)
- Run `flutter clean && flutter pub get` after adding file

### iOS GoogleService-Info.plist Issues
- Ensure file is in Runner project, not just workspace
- Check file is added to correct target (Runner)
- Run `flutter clean && flutter pub get && cd ios && pod repo update && pod install && cd ..`

## Security Notes

⚠️ **Important**: 
- Never commit firebase credentials to public repositories
- Add to `.gitignore`:
  ```
  android/app/google-services.json
  ios/Runner/GoogleService-Info.plist
  ```
- Use Firebase Security Rules to restrict access
- Enable App Check for production

## Production Checklist

- [ ] Firebase project created
- [ ] Android app registered with google-services.json
- [ ] iOS app registered (if building for iOS)
- [ ] Push notification topics configured
- [ ] Backend service authenticated with Firebase Admin SDK
- [ ] Security rules configured
- [ ] App Check enabled
- [ ] Credentials excluded from version control
