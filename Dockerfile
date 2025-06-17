# builder stage
FROM node:20-alpine AS builder
WORKDIR /app
RUN corepack enable
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .

# Hardcode the environment variables for build time
ENV NEXT_PUBLIC_LIVEKIT_URL=wss://livekit.clam.au \
    LIVEKIT_URL=wss://livekit.clam.au \
    DEFAULT_ROOM=hang \
    NEXT_PUBLIC_DEFAULT_ROOM=hang

RUN pnpm build

# runtime stage
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
RUN corepack enable

# copy everything from builder
COPY --from=builder /app/ ./

# Set runtime environment variables to same values
ENV NEXT_PUBLIC_LIVEKIT_URL=wss://livekit.clam.au \
    LIVEKIT_URL=wss://livekit.clam.au \
    DEFAULT_ROOM=hang \
    NEXT_PUBLIC_DEFAULT_ROOM=hang

# install only prod deps
RUN pnpm prune --prod

EXPOSE 3000

LABEL org.opencontainers.image.source=https://github.com/clam-au/meet

# npm start script should run `next start`
CMD ["pnpm", "start"]