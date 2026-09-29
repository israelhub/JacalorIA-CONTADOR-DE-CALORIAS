# syntax=docker/dockerfile:1

# ---- Build stage ----
FROM node:22-bookworm-slim AS builder
WORKDIR /app

# Ferramentas necessarias para compilar dependencias nativas (bcrypt)
RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build \
  && npm prune --omit=dev

# ---- Runtime stage ----
FROM node:22-bookworm-slim AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

COPY package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/assets ./assets
COPY --from=builder /app/public ./public

EXPOSE 3000

CMD ["node", "dist/main.js"]
