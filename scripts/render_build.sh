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

flutter pub get
dart run build_runner build --delete-conflicting-outputs

# --no-web-resources-cdn: sem isto o CanvasKit (~5 MB) é buscado em
# gstatic.com em tempo de execução e o app NÃO renderiza se esse CDN
# estiver lento ou bloqueado. Com a flag, ele sai da mesma origem — que é
# o que já vai no build/web/canvaskit de qualquer forma.
flutter build web --release --no-web-resources-cdn -t lib/main_demo.dart
