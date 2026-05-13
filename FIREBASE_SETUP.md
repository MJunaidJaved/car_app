# 🔥 Firebase Setup Guide

This guide will walk you through setting up Firebase for the CarPool App.

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add Project"** or **"Create a Project"**
3. Enter project name: **CarPool App** (or any name you prefer)
4. Click **Continue**
5. **Disable Google Analytics** (optional for development)
6. Click **Create Project**
7. Wait for project to be created
8. Click **Continue**

---

## Step 2: Add Android App

1. In Firebase Console, click the **Android icon** (or **Add App** > **Android**)
2. Fill in the details:
   - **Android package name:** `com.carpool.app` (must match your app)
   - **App nickname (optional):** CarPool Android
   - **Debug signing certificate SHA-1 (optional):** Leave empty for now
3. Click **Register App**
4. **Download config file:**
   - Click **Download google-services.json**
   - Move this file to: `carpool_app/android/app/google-services.json`
5. Click **Next** (Skip the Gradle setup instructions, already done)
6. Click **Continue to console**

### Verify Android Configuration

Make sure these files exist:
```
carpool_app/
└── android/
    ├── build.gradle (contains google-services plugin)
    └── app/
        ├── build.gradle (has apply plugin at bottom)
        └── google-services.json (downloaded file)
```

---

## Step 3: Add iOS App (Optional - if testing on iOS)

1. In Firebase Console, click **Add App** > **iOS**
2. Fill in the details:
   - **iOS bundle ID:** `com.carpool.app` (must match your app)
   - **App nickname (optional):** CarPool iOS
   - **App Store ID (optional):** Leave empty
3. Click **Register App**
4. **Download config file:**
   - Click **Download GoogleService-Info.plist**
   - Move this file to: `carpool_app/ios/Runner/GoogleService-Info.plist`
5. Click **Next** (Skip SDK setup, already done)
6. Click **Continue to console**

---

## Step 4: Enable Authentication

1. In Firebase Console sidebar, click **Authentication**
2. Click **Get Started**
3. Go to **Sign-in method** tab
4. Click **Email/Password**
5. **Enable** the toggle switch
6. Click **Save**

**Result:** Users can now sign up with email and password.

---

## Step 5: Create Firestore Database

1. In Firebase Console sidebar, click **Firestore Database**
2. Click **Create Database**
3. Select **Start in test mode** (for development)
   - This allows read/write access without authentication initially
   - We'll add security rules next
4. Choose your **Cloud Firestore location**
   - Recommended: Select closest to Pakistan (e.g., asia-south1 Mumbai)
5. Click **Enable**
6. Wait for database to be created

---

## Step 6: Set Firestore Security Rules

1. In Firestore Database, click **Rules** tab
2. Replace the existing rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection
    match /users/{userId} {
      allow read: if true;  // Anyone can read user profiles
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Rides collection
    match /rides/{rideId} {
      allow read: if true;  // Anyone can see available rides
      allow create: if request.auth != null;  // Authenticated users can create
      allow update, delete: if request.auth != null && 
        request.auth.uid == resource.data.captainId;  // Only captain can update/delete
    }
    
    // Deals collection
    match /deals/{dealId} {
      allow read: if request.auth != null;  // Authenticated users can read
      allow create: if request.auth != null;  // Authenticated users can create deals
      allow update: if request.auth != null && 
        (request.auth.uid == resource.data.captainId || 
         request.auth.uid == resource.data.customerId);  // Captain or customer can update
    }
    
    // Wallets collection (Captain only)
    match /wallets/{walletId} {
      allow read: if request.auth != null && request.auth.uid == walletId;
      allow write: if request.auth != null && request.auth.uid == walletId;
    }
    
    // Transactions collection
    match /transactions/{transactionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
  }
}
```

3. Click **Publish**

**Security Rules Explanation:**
- **Users:** Anyone can read profiles, but only the user can update their own
- **Rides:** Public read, authenticated create, only captain can modify their rides
- **Deals:** Authenticated users can read/create, captain and customer can update
- **Wallets:** Private to each captain
- **Transactions:** Authenticated users can read and create

---

## Step 7: Enable Cloud Messaging (Optional - for Push Notifications)

1. In Firebase Console sidebar, click **Cloud Messaging**
2. Note your **Server Key** (you'll need this for sending notifications later)

---

## Step 8: Test Your Setup

### 8.1 Run the App

```bash
cd carpool_app
flutter run
```

### 8.2 Create Test Account

1. Click **Sign Up**
2. Fill in details:
   - Name: Test Captain
   - Email: captain@test.com
   - Password: test123
   - Phone: 03001234567
   - Select: **Offer Rides (Captain)**
   - Fill in vehicle details
3. Click **Create Account**

### 8.3 Verify in Firebase Console

1. Go to **Authentication** > **Users** tab
2. You should see the test user
3. Go to **Firestore Database** > **Data** tab
4. You should see collections: `users` and `wallets`

---

## Step 9: Common Issues & Solutions

### Issue 1: "google-services.json not found"
**Solution:** 
- Ensure file is at `android/app/google-services.json`
- Run `flutter clean` and `flutter pub get`

### Issue 2: "Package name mismatch"
**Solution:** 
- Android package in Firebase must match `applicationId` in `android/app/build.gradle`
- Both should be `com.carpool.app`

### Issue 3: "Firestore permission denied"
**Solution:** 
- Check your Security Rules are set correctly (Step 6)
- Ensure you're logged in (Authentication enabled)

### Issue 4: iOS build fails
**Solution:** 
```bash
cd ios
rm Podfile.lock
rm -rf Pods
pod install
cd ..
flutter clean
flutter run
```

### Issue 5: "FirebaseException: [core/no-app]"
**Solution:** 
- Ensure `google-services.json` (Android) is in correct location
- Ensure `GoogleService-Info.plist` (iOS) is in correct location
- Run `flutter clean` and rebuild

---

## Step 10: Production Checklist

Before deploying to production:

- [ ] Change Firestore rules from **test mode** to **production mode**
- [ ] Add proper security rules for all collections
- [ ] Enable **App Check** for additional security
- [ ] Set up **Firebase Analytics** (optional)
- [ ] Configure **Firebase Performance Monitoring** (optional)
- [ ] Set up **Crashlytics** for crash reporting (optional)
- [ ] Add SHA-1 and SHA-256 fingerprints for Android release builds
- [ ] Configure Firebase Authentication email templates
- [ ] Set up proper backup strategy for Firestore

---

## Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firestore Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)

---

## Need Help?

If you encounter issues:
1. Check the error message in terminal
2. Verify all files are in correct locations
3. Run `flutter doctor` to check Flutter setup
4. Clear cache: `flutter clean && flutter pub get`
5. Check Firebase Console for errors

---

**Your Firebase setup is now complete! 🎉**

You can now run the app and start testing all features.
