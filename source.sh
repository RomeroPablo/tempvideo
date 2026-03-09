#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VIDEO_FILE="${VIDEO_FILE:-$ROOT_DIR/video.mp4}"
SERVER_HOST="${SERVER_HOST:-127.0.0.1}"
SOURCE_PORT="${SOURCE_PORT:-6100}"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Missing required command: ffmpeg"
  exit 1
fi

if [[ ! -f "$VIDEO_FILE" ]]; then
  echo "Missing input video: $VIDEO_FILE"
  exit 1
fi

echo "Source sending to tcp://${SERVER_HOST}:${SOURCE_PORT}"

action() {
  ffmpeg -hide_banner -loglevel warning \
    -re -stream_loop -1 -i "$VIDEO_FILE" \
    -map 0:v:0 -an -c:v libx264 -preset veryfast -tune zerolatency \
    -pix_fmt yuv420p -g 50 -keyint_min 50 \
    -f mpegts "tcp://${SERVER_HOST}:${SOURCE_PORT}"
}

action
