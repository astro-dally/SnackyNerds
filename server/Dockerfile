# ── Stage 1: Build ──────────────────────────────────────
FROM node:20-bookworm-slim AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .
RUN npx prisma generate

# ── Stage 2: Production ────────────────────────────────
FROM node:20-bookworm-slim AS production

# Install runtime dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r snacky && useradd -r -g snacky -m snacky

WORKDIR /app

# Copy built app from builder stage
COPY --from=builder --chown=snacky:snacky /app .

# Switch to non-root user
USER snacky

EXPOSE 5001

# Healthcheck — hits the /api/health endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:5001/api/health || exit 1

CMD ["node", "src/index.js"]
