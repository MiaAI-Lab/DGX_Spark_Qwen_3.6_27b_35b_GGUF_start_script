# llama-server-starter

A robust, production-ready bash script to start and manage [`llama-server`](https://github.com/ggml-org/llama.cpp) from [llama.cpp](https://github.com/ggml-org/llama.cpp).

It handles binary detection, prevents duplicate instances, waits for the server to become healthy, and keeps everything running in the background even after you close the terminal.

## Features

- ✅ Automatic `llama-server` binary detection (PATH + common build locations)
- ✅ PID file management + automatic cleanup of stale processes
- ✅ Health check polling (`/health` endpoint) before declaring ready
- ✅ Persistent logging + background execution via `nohup`
- ✅ Fully configurable via environment variables
- ✅ Clean, colored startup output
- ✅ OpenAI-compatible API ready (`/v1` endpoint)

## Requirements

- Linux (tested on Ubuntu)
- `bash`
- `curl`
- A compiled `llama.cpp` build containing the `llama-server` binary
- Sufficient RAM / VRAM for your model and context size

## Quick Start

```bash
# 1. Make the script executable
chmod +x start.sh

# 2. (Optional) Put your .gguf model next to the script, or set MODEL=...

# 3. Start the server
./start.sh
```

Once it says **"llama-server is ready"**, you can use the OpenAI-compatible endpoint:

```
http://localhost:8000/v1
```

## Configuration

### Environment Variables

| Variable           | Default                           | Description                          |
| ------------------ | --------------------------------- | ------------------------------------ |
| `MODEL`            | `Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf` | Path to your GGUF model file         |
| `LLAMA_SERVER_BIN` | auto-detected                     | Full path to `llama-server` binary   |
| `HOST`             | `0.0.0.0`                         | Bind address                         |
| `PORT`             | `8000`                            | Server port                          |
| `SCRIPT_DIR`       | (directory of the script)         | Used for relative model/binary paths |

**Examples:**

```bash
# Use a different model
MODEL=llama-3.1-70b-Q4_K_M.gguf ./start.sh

# Point to a custom llama.cpp build
LLAMA_SERVER_BIN=~/llama.cpp/build/bin/llama-server ./start.sh

# Change port
PORT=11434 ./start.sh
```

### Customizing Server Flags

All `llama-server` flags are defined inside the script (around the `nohup` line). Common things you might want to change:

- `--ctx-size`
- `--temperature`, `--top-p`, `--top-k`
- Speculative decoding settings (`--spec-type`, `--spec-draft-*`)
- `--chat-template-kwargs`

Just edit the script and restart.

## How It Works

1. Checks if a healthy instance is already running → exits early if so
2. Cleans up stale PID files / processes
3. Launches `llama-server` in the background with `nohup`
4. Polls `http://127.0.0.1:PORT/health` every 5 seconds until ready
5. Prints the ready message + OpenAI base URL

Log file: `.llama-server.log` (in the same directory as the script)

PID file: `.llama-server.pid`

## Recommended Directory Layout

```
~/llama.cpp/
├── build/
│   └── bin/
│       └── llama-server
├── start.sh
├── Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf
└── README.md
```

This layout allows full auto-detection without setting any environment variables.

## Troubleshooting

**"error: llama-server not found"**

Set the full path explicitly:

```bash
LLAMA_SERVER_BIN=/path/to/llama-server ./start.sh
```

**Server starts but never becomes "ready"**

Check the log:

```bash
tail -n 100 .llama-server.log
```

Common causes: out of memory, unsupported flags in your llama.cpp build, or model loading failure.

**Port already in use**

Change the port:

```bash
PORT=9999 ./start.sh
```

## Compatibility

- Works with recent `llama.cpp` builds (speculative decoding + chat template kwargs support recommended)
- Tested on Ubuntu 22.04 / 24.04
- Should work on any modern Linux distro with `bash` and `curl`

## License

MIT

---

Made for convenient local LLM serving with llama.cpp. PRs and improvements welcome!
