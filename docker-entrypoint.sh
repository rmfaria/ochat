#!/bin/sh
set -e

OPENCLAW_STATE="${OPENCLAW_STATE_DIR:-/root/.openclaw}"
AUTH_FILE="$OPENCLAW_STATE/agents/main/agent/auth-profiles.json"

# ── 1. Bootstrap openclaw config from env vars ─────────────────────────────
if [ ! -f "$AUTH_FILE" ]; then
  if [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$OPENAI_API_KEY" ]; then
    echo "[ochat] ERROR: no API keys provided."
    echo "[ochat]   Set ANTHROPIC_API_KEY or OPENAI_API_KEY in your environment."
    exit 1
  fi

  echo "[ochat] bootstrapping openclaw agent config..."
  mkdir -p "$(dirname "$AUTH_FILE")"

  # Build auth-profiles.json from whichever keys are present
  AUTH="{}"
  if [ -n "$ANTHROPIC_API_KEY" ]; then
    AUTH=$(printf '{"anthropic":{"api_key":"%s"}}' "$ANTHROPIC_API_KEY")
  fi
  if [ -n "$OPENAI_API_KEY" ]; then
    OPENAI_BLOCK=$(printf '"openai":{"api_key":"%s"}' "$OPENAI_API_KEY")
    AUTH=$(echo "$AUTH" | sed "s/}$/,$OPENAI_BLOCK}/")
  fi
  echo "$AUTH" > "$AUTH_FILE"
  echo "[ochat] auth-profiles.json written."
fi

# ── 2. Start openclaw gateway in background ────────────────────────────────
echo "[ochat] starting openclaw gateway..."
openclaw gateway --allow-unconfigured &
GATEWAY_PID=$!

# Wait until gateway is ready (up to 20s)
for i in $(seq 1 20); do
  if openclaw gateway status 2>/dev/null | grep -qi "running\|started\|listening"; then
    echo "[ochat] gateway ready."
    break
  fi
  sleep 1
done

# ── 3. Start ochat ─────────────────────────────────────────────────────────
echo "[ochat] starting ochat server on port ${PORT:-18800}..."
exec node dist/index.js
