# Liminal — Build Diagnostics

## Commands

```
flutter build ios --release                   # signed deploy build
flutter build ios --release --no-codesign      # unsigned (quicker, no deploy)
ios-deploy --justlaunch --bundle build/ios/iphoneos/Runner.app  # deploy
flutter clean && flutter pub get               # full reset
flutter devices                                # check connected
rm -rf ios/Pods ios/Podfile.lock && flutter pub get  # deep pod reset
```

## Current Build Failure

`flutter build ios --release` fails after ~575s with:

```
** BUILD INTERRUPTED **
```

Xcode shows only deprecation warnings (fluttertoast, FirebaseAuth) — no errors. The xcresult bundle with the real failure is deleted by Flutter tools before we can read it (`mac.dart` line 537-539 discards `Command PhaseScriptExecution failed with a nonzero exit code`).

### Facts gathered

| Check | Result |
|-------|--------|
| `gen_snapshot_arm64` runs standalone | ✅ |
| Quarantine attribute removed | ✅ |
| `flutter doctor -v` | ✅ clean |
| Brand new Flutter project builds | ✅ (takes 293s but succeeds) |
| Signed vs unsigned | ❌ both fail identically |
| Debug vs release | ❌ both fail identically |
| `dart analyze lib/` | ⚠️ warnings only |
| Xcode 26.3 | Very new, Flutter 3.38.7 is 6 months old |

### Likely cause

The build ALWAYS passes for a fresh `flutter create` project. It ALWAYS fails for the Liminal project. Since the failure hits in both debug and release modes (ruling out `gen_snapshot_arm64`), it's probably:

**The Flutter "Run Script" phase** (`xcode_backend.sh` → `xcode_backend.dart`) executing `flutter assemble` with incorrect or missing environment variables. The script defaults `--output` to `BUILT_PRODUCTS_DIR ?? '/'` — if that variable is somehow empty during Liminal's Xcode build but populated for the fresh project, the assemble command tries to write `.last_build_id` to the root filesystem, which fails with EROFS.

### To debug further

Ask another AI to:

1. **Intercept the xcresult bundle** — Patch `mac.dart` around line 551 to copy the xcresult bundle to a permanent path before the `finally` block deletes it (change line 551-553 from `deleteSync` to `copySync` to `/tmp/xcresult_saved`). Then re-run the build and inspect the saved bundle.

2. **Check that `BUILT_PRODUCTS_DIR` is populated** — Patch `xcode_backend.dart` around line 643 to log the value of `environment['BUILT_PRODUCTS_DIR']` before using it. If it's empty during the Liminal build but populated for a fresh project, that's the smoking gun.

3. **Try the Flutter master channel** — Xcode 26.3 is extremely recent. Flutter 3.38.7 stable (6 months old) may not support it fully. `flutter channel master && flutter upgrade` might resolve the issue.
