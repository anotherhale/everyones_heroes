#!/usr/bin/env bash
# Render Static Site build for Everyone's Heroes Flutter Web (eh-web).
#
# Expects build-time environment variables (set in Render Dashboard / Blueprint):
#   EH_AI_PROXY_URL          — public HTTPS URL of eh-ai-proxy
#   EH_TRANSCRIPTION_MODE    — typically "proxy"
#   EH_AI_PROXY_AUTH_TOKEN   — shared proxy bearer (TEST-ONLY: embedded in JS)
#
# Never pass OPENAI_API_KEY into this script or the Flutter build.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

: "${EH_AI_PROXY_URL:?EH_AI_PROXY_URL must be set for the Render Flutter web build}"
: "${EH_AI_PROXY_AUTH_TOKEN:?EH_AI_PROXY_AUTH_TOKEN must be set for the Render Flutter web build}"
EH_TRANSCRIPTION_MODE="${EH_TRANSCRIPTION_MODE:-proxy}"

FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter}"

if [[ ! -x "$FLUTTER_DIR/bin/flutter" ]]; then
  echo "Cloning Flutter ($FLUTTER_CHANNEL) into $FLUTTER_DIR ..."
  git clone https://github.com/flutter/flutter.git \
    --depth 1 \
    -b "$FLUTTER_CHANNEL" \
    "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter config --no-analytics --enable-web
flutter pub get
flutter build web --release \
  --dart-define="EH_AI_PROXY_URL=${EH_AI_PROXY_URL}" \
  --dart-define="EH_TRANSCRIPTION_MODE=${EH_TRANSCRIPTION_MODE}" \
  --dart-define="EH_AI_PROXY_AUTH_TOKEN=${EH_AI_PROXY_AUTH_TOKEN}"

echo "Flutter web build complete → build/web"
