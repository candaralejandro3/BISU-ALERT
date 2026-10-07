# BISU-Alert Quick Start Guide

Get the BISU-Alert app up and running in 5 minutes!

## ✅ Prerequisites

- Flutter 3.4.0+ installed
- Android SDK configured (or Xcode for iOS)
- A modern code editor (VS Code recommended)
- Internet connection
- Firebase account (for push notifications)

## 🚀 Step 1: Initial Setup (2 minutes)

### Clone/Open Project
```bash
cd c:\BISU-ALERT\BISU-Alert
```

### Install Dependencies
```bash
flutter pub get
```

This downloads all required packages including:
- Firebase messaging (push notifications)
- Google Maps (campus mapping)
- Image picker (camera/gallery)
- Connectivity monitoring
- And 10+ more...

## 🔐 Step 2: Configure Firebase (5 minutes)

### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create Project"
3. Name it "BISU-Alert"
4. Enable Google Analytics (optional)
5. Click "Create"

### Add Android App
1. In Firebase project, click Android icon
2. Enter package name: `com.bisu.alert`
3. Enter app nickname: `BISU-Alert`
4. Enter signing certificate SHA-1: (run command below)
5. Download `google-services.json`

### Get SHA-1 Certificate
```bash
# Windows
cd android
./gradlew signingReport

# Copy the SHA1 value from output
```

### Add google-services.json
1. Move downloaded `google-services.json`
2. Place in: `c:\BISU-ALERT\BISU-Alert\android\app\`

## 🌐 Step 3: Configure API Connection

### Update Backend URL
1. Open: `lib/data/services/api_service.dart`
2. Find line 17: `static const String _baseUrl = '...'`
3. Update with your backend URL:

```dart
// For local development:
static const String _baseUrl = 'http://10.0.2.2:3000';

// For production:
static const String _baseUrl = 'https://api.yourdomain.com';
```

**Note**: Use `10.0.2.2` instead of `localhost` for Android emulator

## 📞 Step 4: Add Emergency Hotlines

### Update Contact Numbers
1. Open: `lib/data/services/sms_alert_service.dart`
2. Update lines 4-13 with real numbers:

```dart
static const String campusSecurityHotline = '+63-XX-XXXX-XXXX'; // BISU Security
static const String policeEmergency = '911';                      // PNP
static const String medicalEmergency = '911';                    // BFP/Ambulance
static const String disasterManagement = '09209662687';          // MDRRMO
```

### Get Real Numbers From:
- BISU Campus Security Office
- Local Police (PNP)
- Local Fire Department (BFP)
- Negros Oriental MDRRMO

## 🎮 Step 5: Run the App

### On Android Emulator
```bash
# Start emulator first, then:
flutter run
```

### On Physical Android Device
```bash
# Connect via USB with developer mode enabled
flutter run
```

### On iOS (Mac only)
```bash
# Requires Xcode setup
flutter run -d ios
```

## 📱 First Time Experience

1. **Login Screen** → Tap "Register" to create account
2. **Profile Setup** → Enter name and ID number
3. **Map Screen** → View campus locations
4. **Home Screen** → See emergency contacts
5. **Report Incident** → Take photo/video, fill form
6. **SOS Button** → Hold 3 seconds to send emergency alert

## 🔧 Troubleshooting

### Build Error: "Target of URI doesn't exist"
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Firebase Error
```bash
# Ensure google-services.json is in android/app/
# Check Firebase console for enabled services
```

### Connection Refused
```bash
# Update API_BASE_URL to match your backend
# For emulator: http://10.0.2.2:3000
# For device: http://YOUR_COMPUTER_IP:3000
```

### Permissions Denied
```bash
# Ensure Android manifest has permissions
# Grant permissions when app first runs
```

## 📚 Next Steps

### Test Locally
```bash
# Without backend (mock data only)
flutter run

# This shows demo data - full features need backend
```

### Set Up Backend
See [SETUP_GUIDE.md](./SETUP_GUIDE.md) for:
- Node.js/Express setup
- MongoDB schema
- Running local server
- Deploying to production

### Run API Tests
Use [API_DOCUMENTATION.md](./API_DOCUMENTATION.md):
- Import Postman collection
- Test all 21 endpoints
- Verify response formats

## 🎯 Key Features Available

### Without Backend
- ✅ Dark mode toggle
- ✅ Map viewing
- ✅ Camera/photo picker
- ✅ Shake detection
- ✅ SOS button
- ✅ Theme switching

### With Backend
- ✅ User login/register
- ✅ Submit incidents
- ✅ View status updates
- ✅ Receive alerts
- ✅ Push notifications
- ✅ Emergency contacts
- ✅ Incident feed
- ✅ Offline caching

## 💻 Development Commands

```bash
# Format code
dart format lib/

# Check for issues
flutter analyze

# Run tests
flutter test

# Build for production
flutter build apk --release

# View detailed logs
flutter logs -v
```

## 📞 Support

For issues:
1. Check [SETUP_GUIDE.md](./SETUP_GUIDE.md)
2. Check [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)
3. Check [IMPLEMENTATION_STATUS.md](./IMPLEMENTATION_STATUS.md)
4. Check Flutter docs at flutter.dev

## ✨ Summary

```
Flutter App: ✅ Ready
Firebase Setup: 📝 Required
Backend API: 🔄 Needs implementation
Deployment: ⏳ After backend ready

Total Setup Time: ~15 minutes
Time to First Run: ~5 minutes
```

---

**Ready to go!** 🚀

Questions? See the complete documentation files or contact your development team.
