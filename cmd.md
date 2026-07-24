# Liminal — Dev Commands

## Build (unsigned — quick test)
```
flutter build ios --release --no-codesign
```

## Build (signed — deploy to device)
```
flutter build ios --release
```

## Deploy to device (after signed build)
```
ios-deploy --justlaunch --bundle build/ios/iphoneos/Runner.app
```

## One-shot: build + deploy (signed)
```
flutter build ios --release && ios-deploy --justlaunch --bundle build/ios/iphoneos/Runner.app
```

## Reset (if builds get weird)
```
flutter clean && flutter pub get
```

## Run on simulator (for UI iteration)
```
flutter run
```

## Check connected devices
```
flutter devices
```
