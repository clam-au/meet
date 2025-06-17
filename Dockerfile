# builder stage
FROM node:20-alpine AS builder
WORKDIR /app

# Enable corepack and copy package files for better caching
RUN corepack enable
COPY package.json pnpm-lock.yaml ./

# Install dependencies (this layer will be cached unless package files change)
RUN pnpm install --frozen-lockfile

# Set build-time environment variables
ENV NEXT_PUBLIC_LIVEKIT_URL=wss://livekit.clam.au \
    LIVEKIT_URL=wss://livekit.clam.au \
    DEFAULT_ROOM=hang \
    NEXT_PUBLIC_DEFAULT_ROOM=hang

# Copy source code (after deps for better layer caching)
COPY . .

# Build the application and prune dev dependencies
RUN pnpm build && pnpm prune --prod

# runtime stage - using distroless for better security and smaller size
FROM gcr.io/distroless/nodejs20-debian12
WORKDIR /app

# Copy only necessary files from builder
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules

# Set runtime environment variables
ENV NODE_ENV=production \
    NEXT_PUBLIC_LIVEKIT_URL=wss://livekit.clam.au \
    LIVEKIT_URL=wss://livekit.clam.au \
    DEFAULT_ROOM=hang \
    NEXT_PUBLIC_DEFAULT_ROOM=hang

EXPOSE 3000

# Enhanced container labels for better metadata
LABEL org.opencontainers.image.source=https://github.com/clam-au/meet \
      org.opencontainers.image.description="ClamCall video conferencing app" \
      org.opencontainers.image.licenses=MIT

# Use Next.js start command directly (distroless doesn't have pnpm)
CMD ["node_modules/.bin/next", "start"]