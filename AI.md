# AI.md — Liminal Build & Bug Notes

Maintain this file when working on Liminal. It tracks build workflow, known bugs, and fixes so recurring issues can be avoided.

## Build & Deploy Workflow

```
flutter devices                                # check connected devices / UDID
flutter build ios --release                    # signed release build -> build/ios/iphoneos/Runner.app
xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app
xcrun devicectl device process launch --device <UDID> com.example.liminal
```

Known device UDID: `1281C606-D60B-5CFA-A88F-1710E9ED53BF` (Caxl, iPhone 13 Pro, iOS 27.0)
Flutter device id: `00008110-00194C840242801E`

## BUG: Debug build white screen + crash on iPhone

### Symptoms
App installed on iPhone, tap icon -> white screen -> crash back to home screen.

### Root cause
The app was deployed as a **debug build** (`flutter run -d <device>` / install of the debug Runner.app). Debug Flutter apps cannot run standalone from the home screen. When launched without Flutter tooling / Xcode attached, the engine aborts:

```
Runner: Cannot create a FlutterEngine instance in debug mode without Flutter tooling or Xcode.
To launch in debug mode in iOS 14+, run flutter run from Flutter tools, run from an IDE with a Flutter IDE plugin or run the iOS project from Xcode.
App terminated due to signal 11.
```

### Fix
Build + install a **release** build so the app launches standalone:

```
flutter build ios --release
xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app
```

Verify it stays running after launch:
```
xcrun devicectl device info processes --device <UDID> | grep -i liminal
xcrun devicectl device process launch --console --device <UDID> com.example.liminal
```
(`--console` keeps it attached; if it exits without output it's running fine — a crash prints the crash reason.)

### Prevent recurrence
- NEVER install a debug Runner.app expecting home-screen launch. Use `flutter run` (debug, stays attached) OR install a release build.
- The iPhone auto-locks and this shows as `Unable to launch ... device was not, or could not be, unlocked` — keep the phone unlocked during install/launch checks.
- Free Apple developer account builds expire after 7 days; when "build expired" appears, just re-run the release build + install flow above.

## BUG: `devicectl` launch fails when phone is locked

Device locks itself -> any `devicectl device process launch` returns:
`Unable to launch com.example.liminal because the device was not, or could not be, unlocked. (FBSOpenApplicationErrorDomain error 7)`
Fix: unlock the phone (keep screen on) before running launch/process checks.

## BUG: "Developer disk image could not be mounted" / device shows "connected (no DDI)"

First run after a long idle / Xcode update can fail to mount the DDI:
```
Timed out waiting for all destinations matching the provided destination specifier to become available
error: The developer disk image could not be mounted on this device.
```
Fix: trigger DDI mount with:
```
xcrun devicectl device info ddiServices --device <UDID>
```
Wait for `• isUsable: true`, then re-run the build.

## Notes

- Xcode 26.3 + iOS 27.0 device; Flutter 3.38.7 (201 days old warning is benign, but old Flutter + new Xcode can cause odd build behavior).
- `flutter run` stays attached and never exits on its own — a shell timeout does NOT mean failure. Check the app is installed/running via `devicectl` instead.
- Release build takes ~2-3 minutes; debug build ~30-60s.
- Build output xcresult saved to `/tmp/liminal_xcresult`.
