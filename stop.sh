#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="${SCRIPT_DIR}/.llama-server.pid"
MODEL="${SCRIPT_DIR}/Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf"
PORT="8000"

find_running_pid() {
  pgrep -f "llama-server .*--model ${MODEL} .*--port ${PORT}" | head -n 1 || true
}

if [[ ! -f "${PID_FILE}" ]]; then
  pid="$(find_running_pid)"
  if [[ -z "${pid}" ]]; then
    echo "No PID file found — llama-server is not running."
    exit 0
  fi
  echo "No PID file found; found running llama-server (pid ${pid})."
else
  pid="$(cat "${PID_FILE}")"
fi

if [[ ! "${pid}" =~ ^[1-9][0-9]*$ ]]; then
  pid="$(find_running_pid)"
  if [[ -z "${pid}" ]]; then
    echo "Invalid PID file contents (removing stale PID file)"
    rm -f "${PID_FILE}"
    exit 0
  fi
  echo "PID file is invalid; found running llama-server (pid ${pid})."
  rm -f "${PID_FILE}"
fi

if ! kill -0 "${pid}" 2>/dev/null; then
  pid="$(find_running_pid)"
  if [[ -z "${pid}" ]]; then
    echo "llama-server is not running (removing stale PID file)"
    rm -f "${PID_FILE}"
    exit 0
  fi
  echo "PID file is stale; found running llama-server (pid ${pid})."
  rm -f "${PID_FILE}"
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
