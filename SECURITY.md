# Liminal Security Architecture

## Overview

Liminal uses a defense-in-depth approach with security enforced at multiple layers:

1. **Firestore Security Rules** — client-side access control
2. **Cloud Functions** — server-side validation and authorization
3. **Firebase App Check** — prevents API abuse from non-app clients
4. **Firebase Auth** — authentication with email/password

## Layers

### 1. Firestore Rules (`firestore.rules`)

Rules are version-controlled and deployed with the project. They enforce:

- **Auth required** for all reads and writes
- **Users collection**: owner-only writes, role field immutable on the client
- **Broadcast collection**: create-only (no update/delete), field length limits, author UID must match authenticated user

### 2. Cloud Functions (`functions/index.js`)

Three server-side functions provide validation that client-side rules cannot:

| Function | Trigger | Purpose |
|----------|---------|---------|
| `onUserCreate` | `users/{userId}` create | Validates role based on email domain. @yvl.dev → developer, @ulk.ac.rw → rep, else → student. Corrects any client-side role escalation. |
| `onBroadcastWrite` | `broadcast/{docId}` create | Verifies author has rep/developer role. Enforces rate limit (5 broadcasts/hour). Deletes unauthorized broadcasts. |
| `onBroadcastCreate` | `broadcast/{docId}` create | Pushes FCM notifications to matching users. Prunes stale tokens. |

### 3. Firebase App Check

App Check uses device attestation to verify requests come from your actual app:

- **iOS/macOS**: DeviceCheck
- **Android**: Play Integrity

Requires configuration in the Firebase Console:
1. Enable App Check in Firebase Console → Project Settings → App Check
2. Register your apps with DeviceCheck (iOS) and Play Integrity (Android)
3. Set App Check to "Enforce" for Firestore and Auth

### 4. Client-Side Controls

- **Dev tools** (Firestore explorer, role simulator, data seeder) are gated behind `kReleaseMode` — they only work in debug/profile builds
- **Input validation** enforces field length limits before Firestore writes
- **Error messages** are user-friendly and never expose internal details

## Role Hierarchy

| Role | Email Domain | Capabilities |
|------|-------------|--------------|
| `student` | Any | Read broadcasts, manage personal tasks |
| `rep` | `@ulk.ac.rw` | + Create broadcasts |
| `developer` | `@yvl.dev` | + Dev tools (debug builds only) |

Role assignment is server-side only. The client never writes `developer` directly.

## Deployment Checklist

After pulling these changes:

1. `cd functions && npm install` — install Cloud Function dependencies
2. `firebase deploy --only firestore:rules` — deploy Firestore rules
3. `firebase deploy --only functions` — deploy Cloud Functions
4. `flutter pub get` — install firebase_app_check
5. Enable App Check in Firebase Console (optional but recommended)
6. Test with Firebase Emulators: `firebase emulators:start`

## What Changed (Hardening Summary)

### Critical Fixes
- Created `firestore.rules` in source control (was only in Firebase Console)
- Moved role assignment to server-side Cloud Function (was client-writable)
- Added server-side broadcast authorization with rate limiting
- Enabled Firebase App Check

### High Fixes
- Dev tools gated behind `kReleaseMode` (were available in release builds)
- Raw error messages replaced with user-friendly strings

### Medium Fixes
- Email validation upgraded from `contains('@')` to regex
- Field length limits added (name: 100, email: 254, title: 200, body: 2000, source: 100)
- `firebase-debug.log` removed and added to `.gitignore`
- Private key patterns (`*.pem`, `*.key`, `*.p12`) added to `.gitignore`
- Syncthing sync-conflict files added to `.gitignore`
