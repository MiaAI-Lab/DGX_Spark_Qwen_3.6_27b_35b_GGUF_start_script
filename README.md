# llama-server starter

Bash scripts to start and stop [`llama-server`](https://github.com/ggml-org/llama.cpp) from [llama.cpp](https://github.com/ggml-org/llama.cpp) for the local GGUF model in this directory.

It handles binary detection, prevents duplicate instances, waits for the server to become healthy, and keeps everything running in the background even after you close the terminal.

## Features

- Automatic `llama-server` binary detection (`PATH`, `./build/bin/llama-server`, or `./llama-server`)
- PID file management and cleanup of stale processes
- Health check polling (`/health` endpoint) before declaring ready
- Persistent logging and background execution via `nohup`
- Simple GGUF file setting at the top of `start.sh`
- OpenAI-compatible API ready (`/v1` endpoint)
- Companion `stop.sh` script for graceful shutdown

## Requirements

- Linux
- `bash`
- `curl`
- A compiled `llama.cpp` build containing the `llama-server` binary
- Sufficient RAM / VRAM for your model and context size

## Quick Start

```bash
# 1. Make the scripts executable
chmod +x start.sh stop.sh

# 2. Put your .gguf model next to the script, or update GGUF_FILE at the top of start.sh

# 3. Start the server
./start.sh
```

Once it says **"llama-server is ready"**, you can use the OpenAI-compatible endpoint:

```
http://localhost:8000/v1
```

### Stopping the Server

```bash
./stop.sh
```

This gracefully stops the running server, waits for clean shutdown, and removes the PID file.

## Configuration

### GGUF File

Set the model file at the top of `start.sh`:

```bash
GGUF_FILE="${GGUF_FILE:-Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf}"
```

Relative paths are resolved from the directory containing `start.sh`.

You can also override the model for one run without editing the file:

```bash
GGUF_FILE=other-model.gguf ./start.sh
```

The older `MODEL` override still works and takes priority over `GGUF_FILE`:

```bash
MODEL=llama-3.1-70b-Q4_K_M.gguf ./start.sh
```

### Other Settings

| Setting             | Default                                      | How to change |
|---------------------|----------------------------------------------|---------------|
| `LLAMA_SERVER_BIN`  | auto-detected                                | Set environment variable |
| `HOST`              | `0.0.0.0`                                    | Edit `start.sh` |
| `PORT`              | `8000`                                       | Edit `start.sh` |
| `PID_FILE`          | `.llama-server.pid`                          | Edit `start.sh` / `stop.sh` |
| `LOG_FILE`          | `.llama-server.log`                          | Edit `start.sh` |

Example:

```bash
LLAMA_SERVER_BIN=~/llama.cpp/build/bin/llama-server ./start.sh
```

To change the port, edit this line in `start.sh`:

```bash
PORT="8000"
```

### Customizing Server Flags

All `llama-server` flags are defined inside `start.sh` (around the `nohup` line). Common things you might want to change:

- `--ctx-size`
- `--temperature`, `--top-p`, `--top-k`
- Speculative decoding settings (`--spec-type`, `--spec-draft-*`)
- `--chat-template-kwargs`

Just edit the script and restart.

## How It Works

**start.sh** does the following:

1. Checks if a healthy instance is already running and exits early if so
2. Cleans up stale PID files / processes
3. Launches `llama-server` in the background with `nohup`
4. Polls `http://127.0.0.1:8000/health` every 5 seconds until ready
5. Prints the ready message + OpenAI base URL

**stop.sh** does the following:

1. Reads the PID from `.llama-server.pid`
2. Sends `SIGTERM` for graceful shutdown
3. Waits up to 15 seconds
4. Force kills with `SIGKILL` only if necessary
5. Cleans up the PID file

**Files created by the scripts:**

- `.llama-server.log` - Server output log
- `.llama-server.pid` - Process ID file

## Recommended Directory Layout

```
./
├── llama-server
├── start.sh
├── stop.sh
├── Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf
└── README.md
```

`llama-server` can be a binary or a symlink to your llama.cpp build. The script also checks `./build/bin/llama-server` and `PATH`.

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

Edit `PORT` in `start.sh`, then start the server again.

The default port is `8000`.

## Compatibility

- Requires a `llama-server` build that supports the flags used in `start.sh`
- Should work on modern Linux distributions with `bash` and `curl`

## License

MIT

---

Made for convenient local LLM serving with llama.cpp.
