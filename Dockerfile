# ochat
# SPDX-License-Identifier: Apache-2.0

# ── Stage 1: builder ──────────────────────────────────────────────────────────
FROM node:22-alpine AS builder

WORKDIR /build

COPY package.json ./
RUN npm install

COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
FROM node:22-slim

# git is required by openclaw's npm install
RUN apt-get update && apt-get install -y --no-install-recommends git wget ca-certificates && rm -rf /var/lib/apt/lists/*

# Install openclaw globally (needs glibc for koffi prebuilt binaries)
# Redirect SSH git URLs to HTTPS (needed for openclaw's WhatsApp/Baileys dependency)
RUN git config --global url."https://github.com/".insteadOf "ssh://git@github.com/" && \
    npm install -g openclaw

WORKDIR /app

# Copy built app and production dependencies
COPY --from=builder /build/dist ./dist
COPY --from=builder /build/node_modules ./node_modules
COPY --from=builder /build/package.json ./

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV PORT=18800
ENV BASE_PATH=
ENV NODE_ENV=production

EXPOSE 18800

HEALTHCHECK --interval=15s --timeout=5s --retries=5 --start-period=30s \
  CMD wget -qO- http://localhost:18800/health || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
