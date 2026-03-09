#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HLS_DIR="$ROOT_DIR/hls"
SOURCE_PORT="${SOURCE_PORT:-6100}"
HTTP_PORT="${HTTP_PORT:-6500}"
BIND_HOST="${BIND_HOST:-0.0.0.0}"
ADVERTISE_HOST="${ADVERTISE_HOST:-$(hostname -I 2>/dev/null | awk '{print $1}')}"
ADVERTISE_HOST="${ADVERTISE_HOST:-127.0.0.1}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1"
    exit 1
  fi
}

require_cmd ffmpeg
require_cmd python3

mkdir -p "$HLS_DIR"
rm -f "$HLS_DIR"/*.m3u8 "$HLS_DIR"/*.ts

cleanup() {
  set +e
  [[ -n "${RELAY_PID:-}" ]] && kill "$RELAY_PID" >/dev/null 2>&1
  [[ -n "${HTTP_PID:-}" ]] && kill "$HTTP_PID" >/dev/null 2>&1
}
trap cleanup EXIT INT TERM

cd "$ROOT_DIR"
python3 -m http.server "$HTTP_PORT" --bind "$BIND_HOST" >/tmp/relay_http.log 2>&1 &
HTTP_PID=$!

echo "Relay server listening for source on tcp://${BIND_HOST}:${SOURCE_PORT}"
echo "Browser sink URL: http://${ADVERTISE_HOST}:${HTTP_PORT}/player.html"
echo

ffmpeg -hide_banner -loglevel warning \
  -i "tcp://${BIND_HOST}:${SOURCE_PORT}?listen=1" \
  -map 0:v:0 -an \
  -c:v libx264 -preset veryfast -tune zerolatency \
  -pix_fmt yuv420p -g 50 -keyint_min 50 -sc_threshold 0 \
  -hls_time 2 -hls_list_size 6 \
  -hls_flags delete_segments+append_list+independent_segments \
  -f hls "$HLS_DIR/stream.m3u8" \
  >/tmp/relay_stream.log 2>&1 &
RELAY_PID=$!

wait "$RELAY_PID"
