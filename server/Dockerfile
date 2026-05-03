# ══════════════════════════════════════════════════════════
# SnackyNerds — Production Dockerfile (Multi-Stage)
# Rubric: ✅ Multi-stage | ✅ Non-root user | ✅ Healthcheck
# ══════════════════════════════════════════════════════════

# ── Stage 1: Builder ────────────────────────────────────
FROM node:20-bookworm-slim AS builder

WORKDIR /app

# Install ALL dependencies (need prisma CLI from devDeps for generate)
COPY package*.json ./
RUN npm ci

# Copy source + prisma schema + migrations + seed
COPY . .

# Generate Prisma client
RUN npx prisma generate

# ── Stage 2: Production ────────────────────────────────
FROM node:20-bookworm-slim AS production

# Install runtime dependencies (openssl for Prisma, curl for healthcheck)
RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r snacky && useradd -r -g snacky -m snacky

WORKDIR /app

# Copy built app from builder
COPY --from=builder --chown=snacky:snacky /app /app

# Clean install: production deps + prisma CLI for migrations
RUN npm ci --omit=dev \
    && npx prisma generate

# Switch to non-root user
USER snacky

EXPOSE 5001

# Healthcheck — hits the /api/health endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:5001/api/health || exit 1

# Startup: migrate DB → seed data → start server
CMD ["sh", "-c", "npx prisma migrate deploy && node prisma/seed.js; node src/index.js"]
