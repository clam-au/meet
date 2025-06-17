// app/api/token/route.ts
export const runtime = 'nodejs';

import { NextRequest, NextResponse } from 'next/server';
import { AccessToken }            from 'livekit-server-sdk';

const KEY    = process.env.LIVEKIT_API_KEY!;
const SECRET = process.env.LIVEKIT_API_SECRET!;
const ROOM   = process.env.DEFAULT_ROOM || 'hangout';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const identity = searchParams.get('identity') ?? crypto.randomUUID();

  // literal grant object, including canUpdateOwnMetadata
  const grant = {
    room: ROOM,
    roomJoin: true,
    canPublish: true,
    canPublishData: true,
    canSubscribe: true,
    canUpdateOwnMetadata: true,
    metadata: identity,   // initial name
  };

  const at = new AccessToken(KEY, SECRET, { identity });
  at.addGrant(grant);

  const token = await at.toJwt();
  return NextResponse.json({ accessToken: token, roomName: ROOM });
}
