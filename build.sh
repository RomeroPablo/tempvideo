#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_PORT="${SOURCE_PORT:-6100}"
SERVER_HOST="${SERVER_HOST:-127.0.0.1}"
HTTP_PORT="${HTTP_PORT:-6500}"
BIND_HOST="${BIND_HOST:-0.0.0.0}"
ADVERTISE_HOST="${ADVERTISE_HOST:-$(hostname -I 2>/dev/null | awk '{print $1}')}"
ADVERTISE_HOST="${ADVERTISE_HOST:-127.0.0.1}"

cleanup() {
  set +e
  [[ -n "${RELAY_PID:-}" ]] && kill "$RELAY_PID" >/dev/null 2>&1
  [[ -n "${SOURCE_PID:-}" ]] && kill "$SOURCE_PID" >/dev/null 2>&1
}
trap cleanup EXIT INT TERM

SOURCE_PORT="$SOURCE_PORT" \
HTTP_PORT="$HTTP_PORT" \
BIND_HOST="$BIND_HOST" \
ADVERTISE_HOST="$ADVERTISE_HOST" \
"$ROOT_DIR/relay-server.sh" &
RELAY_PID=$!

sleep 2

SERVER_HOST="$SERVER_HOST" \
SOURCE_PORT="$SOURCE_PORT" \
"$ROOT_DIR/source.sh" &
SOURCE_PID=$!

echo
echo "Intermediary demo is running: source -> relay server -> browser sink"
echo "Browser sink: http://${ADVERTISE_HOST}:${HTTP_PORT}/player.html"
echo
echo "To run as separate devices/processes:"
echo "1) On server host: BIND_HOST=0.0.0.0 ADVERTISE_HOST=<server-ip> ./relay-server.sh"
echo "2) On source host: SERVER_HOST=<server-ip> ./source.sh"
echo "3) On sink device, open: http://<server-ip>:${HTTP_PORT}/player.html"
echo
echo "Logs:"
echo "  /tmp/relay_stream.log"
echo "  /tmp/relay_http.log"
echo
echo "Press Ctrl+C to stop."

wait
