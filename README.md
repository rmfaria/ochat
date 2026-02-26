# ochat

Web chat interface for [OpenClaw](https://github.com/openclaw/openclaw) — a lightweight Express server that spawns an `openclaw` process per session and streams responses back to the browser over Server-Sent Events (SSE).

## Overview

ochat provides a minimal, self-hosted chat UI to interact with an OpenClaw agent from any browser. It is designed to run as a Docker Swarm service behind Traefik with basic-auth protection.

- Single-file TypeScript server (`src/index.ts`, ~180 lines)
- Per-session OpenClaw subprocess — full isolation between conversations
- Dark space-themed UI, no external dependencies
- Configurable base path for reverse-proxy setups (e.g. `/ochat/`)

## Requirements

- Node.js 22+
- `openclaw` installed globally (`npm install -g openclaw`)
- (Optional) Docker + Swarm + Traefik for production deployment

## Quick start

```bash
npm install
npm run build          # compiles src/index.ts → dist/index.js
npm start              # serves on port 18800
```

Open: http://localhost:18800

### Development (no build step)

```bash
npm run dev
```

## Configuration

All settings via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `18800` | HTTP port |
| `BASE_PATH` | `` | URL prefix (e.g. `/ochat`) for reverse-proxy setups |
| `OPENCLAW_BIN` | `openclaw` | Command used to invoke OpenClaw (override for custom install paths) |

Example with a non-standard openclaw path:

```bash
OPENCLAW_BIN="node /usr/lib/node_modules/openclaw/openclaw.mjs" npm start
```

## Production deployment (Docker Swarm + Traefik)

A ready-to-use Swarm stack is provided in `docker-stack.yml`.

```bash
# Set basic-auth credentials (htpasswd format)
export OCHAT_BASICAUTH='admin:$$apr1$$...'

docker stack deploy -c docker-stack.yml ochat
```

The stack:
- Serves at `https://<host>/ochat/` via Traefik
- Enforces basic-auth (realm: `OpenClaw Chat`)
- Mounts `/opt/ochat` (built app) and `/root/.openclaw` (agent state) from the host
- Mounts the global openclaw package from the host node_modules

## API

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | Chat UI (HTML) |
| `POST` | `/chat` | Start a new OpenClaw session, returns SSE stream |

### POST /chat

**Request:**
```json
{ "message": "your prompt here" }
```

**Response:** `text/event-stream`

Each SSE event contains a chunk of the OpenClaw response. The stream closes when the process exits.

## Related

- [orbit-core](https://github.com/rmfaria/orbit-core) — telemetry platform ochat was originally bundled with
- [OpenClaw](https://github.com/openclaw/openclaw) — the AI agent runtime

## License

Apache-2.0
