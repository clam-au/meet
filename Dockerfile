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

# runtime stage - optimized alpine with security hardening
FROM node:20-alpine
WORKDIR /app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user for better security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Copy built application with proper ownership
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./package.json
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules

# Set runtime environment variables
ENV NODE_ENV=production \
    NEXT_PUBLIC_LIVEKIT_URL=wss://livekit.clam.au \
    LIVEKIT_URL=wss://livekit.clam.au \
    DEFAULT_ROOM=hang \
    NEXT_PUBLIC_DEFAULT_ROOM=hang

# Switch to non-root user
USER nextjs

EXPOSE 3000

# Enhanced container labels for better metadata
LABEL org.opencontainers.image.source=https://github.com/clam-au/meet \
      org.opencontainers.image.description="ClamCall video conferencing app" \
      org.opencontainers.image.licenses=MIT

# Use dumb-init for proper signal handling and pnpm start
ENTRYPOINT ["dumb-init", "--"]
CMD ["node_modules/.bin/next", "start"]