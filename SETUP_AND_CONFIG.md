# Setup & Configuration Guide

This document outlines all the configuration changes made to fix the build and signing issues.

## 🔧 Changes Made

### 1. Environment Variables (`.env`)
- **File Created**: `.env` (root directory)
- **Purpose**: Load environment-specific configuration at app startup
- **Status**: Committed (empty template)
- **How to use**:
  1. Copy `.env.example` to `.env`
  2. Fill in your actual API keys
  ```bash
  PLACES_API_KEY=your_google_places_api_key
  ```

### 2. Google Sign-In Configuration
- **File Modified**: `android/app/google-services.json`
- **Changes**:
  - Added debug key SHA-1 for package `com.shareway.carpool`:
    - SHA-1: `1f11a66847dbe8ba3cd8126e63a70bca1a34f3d7`
  - Added release key SHA-1 for package `com.shareway.carpool`:
    - SHA-1: `0e52c7733ae2011463ba928f9f030c52c1f4a5ce`
- **Status**: Committed ✓
- **Impact**: Fixes `PlatformException(sign_in_failed)` error

### 3. Release Signing Configuration
- **File Created**: `android/key.properties`
- **Status**: NOT committed (sensitive - in .gitignore)
- **Template**: `android/key.properties.example`
- **How to set up**:
  1. Create your release keystore:
     ```bash
     keytool -genkey -v -keystore carpool_release.jks \
       -keyalg RSA -keysize 2048 -validity 10000 \
       -alias carpool_key
     ```
  2. Copy `android/key.properties.example` to `android/key.properties`
  3. Fill in the correct paths and passwords
  4. Build release APK:
     ```bash
     flutter build apk --release
     ```

### 4. Dependency Management
- **Status**: All Flutter dependencies installed
- **Key packages**:
  - `flutter_dotenv: ^5.1.0` - Environment variable loading
  - `firebase_core: ^2.32.0` - Firebase initialization
  - `google_sign_in: ^6.3.0` - Google Sign-In
  - `cloud_firestore: ^4.17.5` - Firestore database
  - `firebase_messaging: ^14.7.10` - Push notifications
  - `firebase_storage: ^11.5.6` - File storage
  - And many more... (see `pubspec.yaml`)

## 🚀 Building the App

### Debug Build (for testing)
```powershell
cd your_project_directory
flutter clean
flutter pub get
flutter build apk
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release Build (for production)
```powershell
cd your_project_directory
flutter clean
flutter pub get
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Release App Bundle (for Google Play Store)
```powershell
flutter build appbundle
# Output: build/app/outputs/bundle/release/app-release.aab
```

## 🔑 Important Notes

### Sensitive Files (NOT committed to git)
- `.env` - Contains API keys
- `android/key.properties` - Contains keystore passwords
- `android/KeyStore/carpool_release.jks` - Release signing key

These should be:
1. Created locally from `.example` templates
2. Never pushed to GitHub
3. Shared securely with team members (preferably through secure vaults)

### Firebase Configuration
- **Project ID**: `carpoolapp-f3b29`
- **Package Name**: `com.shareway.carpool`
- **Console**: https://console.firebase.google.com/
- Both debug and release keys are registered and authorized

### Backend API
- **URL**: http://0.0.0.0:7860 (or your deployed backend)
- **Health Check**: http://0.0.0.0:7860/health
- **API Base**: https://huzaifa1435-carpool.hf.space/api (production)

## ✅ Verification Checklist

- [x] Flutter dependencies installed
- [x] `.env` file created (with template)
- [x] `google-services.json` configured for correct package name
- [x] Firebase keys registered for both debug and release
- [x] Release keystore generated
- [x] `key.properties` configured
- [x] Backend API running and accessible
- [x] Git repository configured
- [x] All changes committed and ready to push

## 🐛 Troubleshooting

### "No file or variants found for asset: .env"
- Ensure `.env` file exists in project root
- Run `flutter clean && flutter pub get`

### "PlatformException(sign_in_failed, ...)"
- Check that package name matches `com.shareway.carpool`
- Verify SHA-1 fingerprints in `google-services.json`
- Ensure device time is correct (many auth failures are due to clock skew)

### "No key.properties file found"
- Create `android/key.properties` from `android/key.properties.example`
- Fill in all paths and passwords correctly
- Ensure keystore file exists at the specified path

### Build fails with "Execution failed for task ':app:compileFlutterBuildRelease'"
- Run `flutter clean`
- Run `flutter pub get`
- Check that all required dependencies are installed: `flutter doctor`
- Ensure Java version 17+ is installed (required for latest Gradle)

## 📝 Next Steps

1. **Local Setup**:
   ```bash
   cp .env.example .env
   # Edit .env and add your API keys
   
   cp android/key.properties.example android/key.properties
   # Edit android/key.properties with your keystore info
   ```

2. **Build & Test**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk
   ```

3. **Push to Play Store** (when ready):
   ```bash
   flutter build appbundle
   # Upload app-release.aab to Google Play Console
   ```

---

**Last Updated**: 2026-06-21  
**Status**: ✅ Production Ready

