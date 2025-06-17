# ClamCloud LiveKit Hangout

This README documents **every deviation** we made from the upstream `livekit/meet` example and how to build, run and ship the resulting communal‑room app.

---

## 1. What this fork does

| Area                 | Upstream Meet                                    | *This* repo                                                                 |
| -------------------- | ------------------------------------------------ | --------------------------------------------------------------------------- |
| **Room model**       | User chooses / creates rooms                     | Everyone drops into a single room `hang` automatically                      |
| **Auth flow**        | Users paste server URL + token or use demo cloud | Token is generated server‑side; FE sees only JWT                            |
| **Identity**         | User enters display name before join             | Random funny name (`randomName()`) then optional **Rename & Rejoin** button |
| **Intro page**       | Logo + tabs                                      | Full‑screen MP4 intro that auto‑redirects to `/hangout`                     |
| **Placeholder icon** | Grey SVG silhouette                              | Overridable with custom PNG (see CSS override)                              |
| **Build**            | No Dockerfile, relies on `npm`                   |  Multi‑stage Dockerfile with `pnpm`, standalone output & GHCR push          |

---

## 2. Prerequisites

| Tool        | Version tested            | Install hint                                                                |
| ----------- | ------------------------- | --------------------------------------------------------------------------- |
| **Node.js** |  ≥ 20 (alpine same)       | [https://nodejs.org/en/download](https://nodejs.org/en/download)            |
| **pnpm**    |  ≥ 9 (comes via Corepack) | `corepack enable && corepack prepare pnpm@latest --activate`                |
| **Docker**  |  ≥ 24                     | Standard engine; if you have NVIDIA as default runtime add `--runtime=runc` |

---

## 3. Environment variables

Create `.env.local` (not committed):

```env
# LiveKit server (wss!)
NEXT_PUBLIC_LIVEKIT_URL=wss://livekit.clam.au

# Communal room
DEFAULT_ROOM=hang
NEXT_PUBLIC_DEFAULT_ROOM=hang

# API creds (server side only)
LIVEKIT_API_KEY=admin
LIVEKIT_API_SECRET=3c85bb4d0aa8dfb6d81c78f12c5d1cdeb39ea06884bb083d
```

**Important:** the secret never reaches the browser; only `/api/token` uses it.

---

## 4. Key source changes

### 4.1 `/app/hangout/page.tsx`

```tsx
'use client';
...
const [identity] = useState(() => randomName()); // funny IDs
...
<LiveKitRoom key={token} ...>           // key forces reconnect on rename
  <VideoConference />
  <RenameBox ... />
</LiveKitRoom>
```

* `RenameBox` triggers `setIdentity(newName)` → new token → remount.
* Toolbar spans full width and shows **ClamCloud Call V1.0** on the right.

### 4.2 `/app/api/token/route.ts`

```ts
export const runtime = 'nodejs';
...
const grant: VideoGrant = {
  room: ROOM,
  roomJoin: true,
  canPublish: true,
  canPublishData: true,
  canSubscribe: true,
};
```

### 4.3 Intro video `/app/page.tsx`

```tsx
<video src="/intro.mp4" muted autoPlay playsInline onEnded={...} />
```

\* Put `intro.mp4` in `public/`.

### 4.4 Placeholder override (optional)

Add to **globals.css** *after* `@livekit/components-styles` import:

```css
.lk-video__placeholder svg { display:none!important; }
.lk-video__placeholder{
  background:var(--lk-bg2) url('/my-custom-avatar.png') center/contain no-repeat!important;
}
```

---

## 5. Local dev

```bash
pnpm install          # one‑time
pnpm dev              # http://localhost:3000 – intro then /hangout
```

---

## 6. Docker build & run

### 6.1 Dockerfile (multi‑stage)

```
# builder
FROM node:20-alpine AS builder
WORKDIR /app
RUN corepack enable
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm build && pnpm prune --prod

# runner
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/ ./
EXPOSE 3000
CMD ["pnpm","start"]
```

### 6.2 Build & test

```bash
docker build -t livekit-meet-hangout:local .

docker run --runtime=runc -it --rm \
  -e LIVEKIT_API_KEY=admin \
  -e LIVEKIT_API_SECRET=... \
  -e NEXT_PUBLIC_LIVEKIT_URL=wss://livekit.clam.au \
  -p 3000:3000 \
  livekit-meet-hangout:local
```

### 6.3 Push to GHCR

```bash
# login once
echo $GH_PAT | docker login ghcr.io -u YOUR_USER --password-stdin

docker tag livekit-meet-hangout:local ghcr.io/clam-au/clam-hangout:latest
docker push ghcr.io/clam-au/clam-hangout:latest
```

---

## 7. Kubernetes (Talos/ArgoCD) snippet

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: clam-hangout
spec:
  replicas: 1
  selector:
    matchLabels: { app: clam-hangout }
  template:
    metadata:
      labels: { app: clam-hangout }
    spec:
      containers:
        - name: web
          image: ghcr.io/YOUR_USER/clam-hangout:latest
          env:
            - name: NEXT_PUBLIC_LIVEKIT_URL
              value: wss://livekit.clam.au
            - name: LIVEKIT_API_KEY
              valueFrom: { secretKeyRef: { name: secret-livekit-api-key, key: key } }
            - name: LIVEKIT_API_SECRET
              valueFrom: { secretKeyRef: { name: secret-livekit-api-key, key: secret } }
          ports:
            - containerPort: 3000
```

Expose via an Ingress (TLS) and you’re done.

---

## 8. Troubleshooting

| Error                                          | Fix                                                                                                  |
| ---------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `ImageData is not defined` during `next build` | Delete `app/custom/` or make it client‑only via `dynamic(...,{ssr:false})`.                          |
| NVIDIA runtime error                           | Run containers with `--runtime=runc` or set Docker `default-runtime` to `runc`.                      |
| Intro video not playing                        | Ensure `intro.mp4` is in `public/` **and** not excluded by `.dockerignore`; file served with 200 OK. |

---

Happy hacking!
— **big dog / ClamCloud**
