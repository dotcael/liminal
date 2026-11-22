# Liminal

A Flutter app with Firebase-backed authentication, role-based feeds and push notifications. Built solo, 2026.

This public copy omits Firebase configuration, Cloud Functions and local build state. To run it,
add your own Firebase project and `lib/firebase_options.dart` with `flutterfire configure`.

## What is in here

- Authentication with email and password through Firebase Auth
- Role-based access: developer, representative and student, assigned server-side
- Feed, profile, settings, splash and shell screens
- Firestore rules that keep the role field immutable on the client
- Cross-platform Flutter project files for iOS, Android, web, macOS, Linux and Windows

## What is deliberately absent

- `firebase.json`, `.firebaserc` and `lib/firebase_options.dart`
- `android/app/google-services.json` and platform `GoogleService-Info.plist` files
- Cloud Functions and local build artefacts
- Device identifiers, Xcode user data and internal diagnostics

## Build

```bash
flutter pub get
flutter run
```

For iOS release builds, configure signing with your own Apple developer account. Free personal
team builds expire after seven days.

## Status

The source compiles on the current toolchain. A signed release install requires an Apple account
and a provisioning profile in Xcode.
