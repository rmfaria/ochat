# ochat

Web chat interface for [OpenClaw](https://github.com/openclaw/openclaw) — a lightweight Express server that manages OpenClaw agent sessions and returns responses to the browser.

## Overview

ochat provides a minimal, self-hosted chat UI to interact with an OpenClaw agent from any browser.

- Single-file TypeScript server (`src/index.ts`, ~180 lines)
- Per-session OpenClaw subprocess — full isolation between conversations
- Dark space-themed UI, no external dependencies
- Configurable base path for reverse-proxy setups (e.g. `/ochat/`)

---

## Docker (recommended)

The easiest way to run ochat. No Node.js or openclaw required on the host.

```bash
git clone https://github.com/rmfaria/ochat.git
cd ochat
cp .env.example .env
# Edit .env — set ANTHROPIC_API_KEY or OPENAI_API_KEY
docker compose up -d
```

Open: **http://localhost:18800**

On first startup, ochat bootstraps the OpenClaw gateway config automatically from your API key.

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ANTHROPIC_API_KEY` | — | Anthropic API key (at least one provider required) |
| `OPENAI_API_KEY` | — | OpenAI API key |
| `OCHAT_PORT` | `18800` | Host port |
| `BASE_PATH` | `` | URL prefix for reverse-proxy (e.g. `/ochat`) |

See [INSTALL.md](INSTALL.md) for the full guide including production deployment, Swarm/Traefik setup, and troubleshooting.

---

## Native (Node.js)

Requires Node.js 22+ and `openclaw` installed globally.

```bash
npm install -g openclaw
npm install
npm run build          # compiles src/index.ts → dist/index.js
npm start              # serves on port 18800
```

### Development (no build step)

```bash
npm run dev
```

### Native environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `18800` | HTTP port |
| `BASE_PATH` | `` | URL prefix for reverse-proxy setups |
| `OPENCLAW_BIN` | `openclaw` | OpenClaw invocation command (override for custom paths) |

```bash
OPENCLAW_BIN="node /usr/lib/node_modules/openclaw/openclaw.mjs" npm start
```

---

## Production: Docker Swarm + Traefik

```bash
export ORBIT_HOST=your.domain.com
export OCHAT_BASICAUTH='admin:$$apr1$$...'   # htpasswd -nb admin yourpassword
docker stack deploy -c docker-stack.yml ochat
```

Serves at `https://<ORBIT_HOST>/ochat/` with HTTP Basic Auth via Traefik.

---

## API

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | Chat UI (HTML) |
| `GET` | `/health` | Health check |
| `POST` | `/api/chat` | Send a message, get agent response |

### POST /api/chat

**Request:**
```json
{ "message": "your prompt here", "sessionId": "optional-uuid" }
```

**Response:**
```json
{ "ok": true, "text": "agent response", "sessionId": "uuid" }
```

Sessions are identified by `sessionId`. Reuse the same ID to continue a conversation.

---

## Related

- [INSTALL.md](INSTALL.md) — full installation guide
- [orbit-core](https://github.com/rmfaria/orbit-core) — telemetry platform ochat was originally bundled with
- [OpenClaw](https://github.com/openclaw/openclaw) — the AI agent runtime

## License

Apache-2.0
