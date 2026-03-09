#!/usr/bin/env bash
set -euo pipefail

SERVER_HOST="${SERVER_HOST:-127.0.0.1}"
HTTP_PORT="${HTTP_PORT:-8080}"

URL="http://${SERVER_HOST}:${HTTP_PORT}/stream.sdp"

echo "Opening sink from: ${URL}"

if command -v vlc >/dev/null 2>&1; then
  vlc "$URL"
else
  echo "VLC not found. Open this URL manually in VLC:"
  echo "  $URL"
fi
