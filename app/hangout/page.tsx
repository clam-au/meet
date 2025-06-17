// app/hangout/page.tsx
'use client';


import {
  LiveKitRoom,
  VideoConference,
} from '@livekit/components-react';
import { useEffect, useState } from 'react';
import { randomName } from '@/lib/randomName';

export default function Hangout() {
  // 1) identity drives both display + token
  const [identity, setIdentity] = useState(() => randomName());
  // 2) fetch a fresh token whenever identity changes
  const [token, setToken] = useState<string>();

  useEffect(() => {
    (async () => {
      const res = await fetch(`/api/token?identity=${encodeURIComponent(identity)}`);
      const { accessToken } = await res.json();
      setToken(accessToken);
    })().catch(console.error);
  }, [identity]);

  // don’t render until we have a token
  if (!token) return null;

  return (
    // key={token} forces LiveKitRoom to unmount/remount on every token change
    <LiveKitRoom
      key={token}
      serverUrl={process.env.NEXT_PUBLIC_LIVEKIT_URL!}
      token={token}
      connect
    >
      <VideoConference />

      {/* Rename UI */}
      <RenameBox
        currentName={identity}
        onRename={(newName) => setIdentity(newName)}
      />
    </LiveKitRoom>
  );
}

type RenameBoxProps = {
  currentName: string;
  onRename: (newName: string) => void;
};

function RenameBox({ currentName, onRename }: RenameBoxProps) {
  const [draft, setDraft] = useState(currentName);

  return (
    <div
      style={{
        position: 'fixed',
        bottom: 10,
        left: 20,
        zIndex: 9999,
        background: 'var(--lk-bg1)',
        padding: 10,
        borderRadius: 6,
        display: 'flex',
        gap: 8,
        alignItems: 'center',
        color: 'white',
      }}
    >
      <input
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        style={{
          padding: '4px 6px',
          fontSize: '1rem',
          borderRadius: 4,
          border: '1px solid #ccc',
        }}
      />
      <button
        onClick={() => onRename(draft)}
        style={{
          padding: '6px 12px',
          fontSize: '1rem',
          cursor: 'pointer',
          borderRadius: 4,
          border: 'none',
          background: '#0070f3',
          color: 'white',
        }}
      >
        Rename
      </button>
      <div style={{ flex: 1 }} />  {/* pushes the next span to the right */}
    </div>
  );
}
