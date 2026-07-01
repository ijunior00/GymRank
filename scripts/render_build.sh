#!/usr/bin/env bash
# Build script for the Render static-site preview of GymRank.
#
# Builds the DEMO entrypoint (lib/main_demo.dart): the whole app runs on
# in-memory fake data, with NO Firebase and NO network calls. This is a
# UI/navigation preview for validation only — it is not the production app
# (which boots from lib/main.dart and requires a real Firebase project).
set -euo pipefail

FLUTTER_VERSION="3.44.4"
FLUTTER_SDK_DIR="${FLUTTER_HOME:-$HOME/flutter}"

if [ ! -x "$FLUTTER_SDK_DIR/bin/flutter" ]; then
  echo "Downloading Flutter $FLUTTER_VERSION ..."
  curl -sSL -o /tmp/flutter.tar.xz \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  mkdir -p "$FLUTTER_SDK_DIR"
  tar -xf /tmp/flutter.tar.xz -C "$FLUTTER_SDK_DIR" --strip-components=1
fi
export PATH="$FLUTTER_SDK_DIR/bin:$PATH"

git config --global --add safe.directory "$FLUTTER_SDK_DIR" || true
flutter config --no-analytics >/dev/null 2>&1 || true

# The web/ platform folder is generated on demand (it is not committed).
if [ ! -d web ]; then
  rm -rf /tmp/web_scaffold
  flutter create --platforms=web --org com.gymrank --project-name gymrank /tmp/web_scaffold
  cp -r /tmp/web_scaffold/web web
fi

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build web --release -t lib/main_demo.dart
