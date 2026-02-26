# ochat — Installation Guide

ochat is a self-hosted web chat interface for [OpenClaw](https://github.com/openclaw/openclaw).
It runs an Express server that manages OpenClaw agent sessions and streams responses back to the browser.

---

## Table of Contents

1. [Requirements](#requirements)
2. [Quick Start](#quick-start)
3. [Configuration](#configuration)
4. [Verifying the Installation](#verifying-the-installation)
5. [Production: Docker Swarm + Traefik](#production-docker-swarm--traefik)
6. [Operations](#operations)
7. [Troubleshooting](#troubleshooting)

---

## Requirements

| Dependency | Minimum | Notes |
|-----------|---------|-------|
| Docker | 24.0 | `docker --version` |
| Docker Compose | 2.20 | bundled with Docker Desktop |
| RAM | 512 MB | for the container |
| API key | — | Anthropic or OpenAI key required |

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/rmfaria/ochat.git
cd ochat

# 2. Create your environment file
cp .env.example .env
# Edit .env and set your API key:
#   ANTHROPIC_API_KEY=sk-ant-...
# or
#   OPENAI_API_KEY=sk-proj-...

# 3. Build and start
docker compose up -d

# 4. Open the UI
# http://localhost:18800
```

> On first startup, ochat bootstraps the OpenClaw agent config automatically
> from your API key. No manual configuration needed.

---

## Configuration

All settings are environment variables in `.env`:

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `ANTHROPIC_API_KEY` | — | One of these | Anthropic API key |
| `OPENAI_API_KEY` | — | One of these | OpenAI API key |
| `OCHAT_PORT` | `18800` | No | Host port |
| `BASE_PATH` | `` | No | URL prefix for reverse-proxy (e.g. `/ochat`) |

At least one provider API key is required. If both are provided, Anthropic is used as the primary provider.

### Getting an Anthropic API key

1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Create an account and navigate to **API Keys**
3. Click **Create Key** and copy the `sk-ant-...` value into `.env`

---

## Verifying the Installation

### 1. Service health

```bash
docker compose ps
```

Expected:

```
NAME            STATUS         PORTS
ochat-ochat-1   Up (healthy)   0.0.0.0:18800->18800/tcp
```

### 2. Health endpoint

```bash
curl http://localhost:18800/health
# Expected: {"ok":true}
```

### 3. Send a test message

```bash
curl -s -X POST http://localhost:18800/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "hello", "sessionId": "test-001"}'
```

Expected:

```json
{"ok": true, "text": "...", "sessionId": "test-001"}
```

### 4. Open the UI

Navigate to **http://localhost:18800** in your browser.
Type a message and hit Enter or click **Enviar**.

---

## Production: Docker Swarm + Traefik

For production deployment behind Traefik with HTTPS and basic-auth, use the provided Swarm stack.

### Prerequisites

- Running Docker Swarm cluster (`docker swarm init`)
- Traefik deployed with `websecure` entrypoint and `letsencryptresolver`
- External overlay network (default: `Portn8n`)

### Deploy

```bash
# Generate a basic-auth password hash
# (requires apache2-utils: apt install apache2-utils)
htpasswd -nb admin your-password
# Output: admin:$apr1$...

# Set required variables
export ORBIT_HOST=your.domain.com
export OCHAT_BASICAUTH='admin:$$apr1$$...'   # double $ to escape in shell

# Deploy the stack
docker stack deploy -c docker-stack.yml ochat
```

> **Note:** The Swarm stack mounts `/opt/ochat` from the host.
> Build the app first: `npm install && npm run build`
> then copy the output to `/opt/ochat/` on the manager node.

### What the stack configures

- **URL:** `https://<ORBIT_HOST>/ochat/`
- **Auth:** HTTP Basic Auth (realm: *OpenClaw Chat*)
- **Strip prefix:** `/ochat` stripped before reaching the app
- **TLS:** auto-provisioned via Let's Encrypt

---

## Operations

### View logs

```bash
docker compose logs -f
```

### Restart

```bash
docker compose restart
```

### Update to a new version

```bash
git pull
docker compose build
docker compose up -d
```

### Stop (preserves session state)

```bash
docker compose down
```

### Stop and wipe all session state

```bash
docker compose down -v
```

---

## Troubleshooting

### Container stays in `health: starting` for more than 60s

The OpenClaw gateway takes 20–30s to initialize on first run.
Check what's happening:

```bash
docker compose logs -f
```

If you see `auth token was missing. Generated a new token`, the gateway is starting normally.
Wait another 10–15s for the ochat server to come online.

### `{"ok": false, "error": "No API key found for provider..."}`

The API key in `.env` was not picked up. Verify:

```bash
docker compose exec ochat sh -c "cat /root/.openclaw/agents/main/agent/auth-profiles.json"
```

If the file is missing or empty, check that `ANTHROPIC_API_KEY` is set in `.env` and recreate:

```bash
docker compose down -v   # wipe state
docker compose up -d     # re-bootstrap with key from .env
```

### Port 18800 already in use

Change `OCHAT_PORT` in `.env`:

```env
OCHAT_PORT=18801
```

Then `docker compose up -d`.

### `{"ok": false, "error": "agent error"}` on every message

The OpenClaw gateway may not be ready yet. Check:

```bash
docker compose logs ochat | grep -E "gateway|ochat"
```

If the gateway log shows `[gateway] listening`, the gateway is up.
If the log shows only `starting openclaw gateway...` with nothing after, wait ~30s.
