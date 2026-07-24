#!/bin/bash
# iOS build helper — works around flaky HTTPS git clones of firebase-ios-sdk
# by pre-cloning the repo locally and intercepting CocoaPods' clone attempt.
set -e

CACHED_REPO="$HOME/Library/Caches/CocoaPods/Pods/GitHub/firebase-ios-sdk.git"
FIREBASE_URL="https://github.com/firebase/firebase-ios-sdk.git"
TAG="CocoaPods-11.15.0"
BUILD_MODE="${1:-release}"

# 1. Ensure local clone exists (retry up to 5 times)
if [ ! -d "$CACHED_REPO/.git" ]; then
  echo "Pre-cloning firebase-ios-sdk (shallow) to cache..."
  mkdir -p "$(dirname "$CACHED_REPO")"
  for i in 1 2 3 4 5; do
    if git clone --depth 1 --branch "$TAG" "$FIREBASE_URL" "$CACHED_REPO" 2>/dev/null; then
      echo "Clone succeeded on attempt $i"
      break
    fi
    rm -rf "$CACHED_REPO" 2>/dev/null
    if [ $i -eq 5 ]; then
      echo "ERROR: All 5 clone attempts failed. Check your network."
      exit 1
    fi
    echo "Attempt $i failed, retrying in 5s..."
    sleep 5
  done
else
  echo "Cache hit — using existing clone at $CACHED_REPO"
fi

# 2. Install git wrapper in a PATH-early directory
REAL_GIT=$(/usr/bin/which git 2>/dev/null)
WRAPPER_DIR="$HOME/.bun/bin"  # first entry in PATH
mkdir -p "$WRAPPER_DIR"

cat > "$WRAPPER_DIR/git" << 'GITWRAP'
#!/bin/bash
CACHED_REPO="$HOME/Library/Caches/CocoaPods/Pods/GitHub/firebase-ios-sdk.git"
REAL_GIT="/usr/local/Homebrew/bin/git"

if [ ! -x "$REAL_GIT" ]; then
  for p in /usr/local/bin/git /usr/bin/git /opt/homebrew/bin/git; do
    if [ -x "$p" ]; then
      REAL_GIT=$(perl -e 'print readlink("'"$p"'") || "'"$p"'"')
      if [[ "$REAL_GIT" != /* ]]; then
        REAL_GIT="$(dirname "$p")/$REAL_GIT"
      fi
      break
    fi
  done
fi

if [ "$1" = "clone" ] && [[ "$*" == *"firebase-ios-sdk.git"* ]]; then
  args=("$@")
  dest=""
  for ((i=${#args[@]}-1; i>=0; i--)); do
    if [[ "${args[$i]}" != -* ]] && [[ "${args[$i]}" != "clone" ]] && [[ "${args[$i]}" != *"firebase-ios-sdk.git"* ]]; then
      dest="${args[$i]}"
      break
    fi
  done
  if [ -n "$dest" ]; then
    rm -rf "$dest" 2>/dev/null
    mkdir -p "$(dirname "$dest")"
    cp -R "$CACHED_REPO/." "$dest/"
    chmod -R u+w "$dest/"
    cd "$dest" && "$REAL_GIT" checkout -f 2>/dev/null || true
    exit 0
  fi
fi
exec "$REAL_GIT" "$@"
GITWRAP
chmod +x "$WRAPPER_DIR/git"

# 3. Fix the HOME reference in the wrapper
sed -i '' "s|\$HOME|$HOME|g" "$WRAPPER_DIR/git"

# 4. Run flutter build
echo "Running flutter build ios --$BUILD_MODE ..."
cd "$(dirname "$0")/.."
flutter build ios "--$BUILD_MODE"

# 5. Clean up wrapper
rm -f "$WRAPPER_DIR/git"

echo "Build complete."
