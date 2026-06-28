#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="${SCRIPT_DIR}/.llama-server.pid"

if [[ ! -f "${PID_FILE}" ]]; then
  echo "No PID file found — llama-server is not running."
  exit 0
fi

pid="$(cat "${PID_FILE}")"

if [[ -z "${pid}" ]] || ! kill -0 "${pid}" 2>/dev/null; then
  echo "llama-server is not running (removing stale PID file)"
  rm -f "${PID_FILE}"
  exit 0
fi

echo "Stopping llama-server (pid ${pid})..."

# Try graceful shutdown first (SIGTERM)
kill "${pid}" 2>/dev/null || true

# Wait up to 15 seconds for clean shutdown
for i in {1..15}; do
  if ! kill -0 "${pid}" 2>/dev/null; then
    break
  fi
  sleep 1
done

# Force kill if still alive
if kill -0 "${pid}" 2>/dev/null; then
  echo "Process did not exit gracefully — force killing..."
  kill -9 "${pid}" 2>/dev/null || true
  sleep 1
fi

rm -f "${PID_FILE}"
echo "llama-server stopped successfully."