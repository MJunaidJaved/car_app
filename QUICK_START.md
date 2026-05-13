# 🚀 Quick Start Guide

Get the CarPool App running in 5 minutes!

---

## ⚡ Quick Setup

### 1. Install Dependencies
```bash
cd carpool_app
flutter pub get
```

### 2. Firebase Setup (5 minutes)

**A. Create Firebase Project:**
- Go to https://console.firebase.google.com/
- Click "Add Project" → Name it "CarPool App"
- Disable Analytics → Create

**B. Add Android App:**
- Click Android icon
- Package name: `com.carpool.app`
- Download `google-services.json`
- Place it in: `android/app/google-services.json`

**C. Enable Authentication:**
- Firebase Console → Authentication → Get Started
- Sign-in method → Email/Password → Enable → Save

**D. Create Firestore Database:**
- Firebase Console → Firestore Database → Create Database
- Start in **test mode** → Select location → Enable

**E. Set Security Rules:**
- Firestore → Rules tab → Copy rules from FIREBASE_SETUP.md → Publish

### 3. Run the App
```bash
flutter run
```

### 4. Test It!
- Click "Sign Up"
- Create account (Captain or Passenger)
- Explore features!

---

## 📱 Test Accounts

**Captain:**
- Email: captain@test.com
- Password: test123
- Role: Driver
- Features: Post rides, manage bookings, wallet

**Passenger:**
- Email: passenger@test.com
- Password: test123
- Role: Passenger
- Features: Find rides, send requests, rate drivers

---

## 🔧 Troubleshooting

**App won't build?**
```bash
flutter clean
flutter pub get
flutter run
```

**Firebase errors?**
- Check `google-services.json` is in `android/app/`
- Verify package name matches in Firebase Console

**iOS build fails?**
```bash
cd ios
pod install
cd ..
flutter run
```

---

## 📚 Full Documentation

- **README.md** - Complete project documentation
- **FIREBASE_SETUP.md** - Detailed Firebase setup guide

---

## ✅ Features to Test

### As Captain:
1. Sign up as Captain
2. Add vehicle details
3. Post a ride (Wah → Haripur)
4. Add funds to wallet
5. View/accept ride requests
6. Complete ride

### As Passenger:
1. Sign up as Passenger
2. Search for rides
3. Send ride request
4. Get captain's number after acceptance
5. Rate the ride

---

## 🎯 Quick Commands

```bash
# Run app
flutter run

# Build APK
flutter build apk --release

# Clean build
flutter clean && flutter pub get

# Check setup
flutter doctor

# Run tests
flutter test
```

---

**Need help? Check README.md for detailed instructions!**
