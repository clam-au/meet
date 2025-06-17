// app/page.tsx
'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useRef } from 'react';

export default function IntroPage() {
  const router = useRouter();
  const videoRef = useRef<HTMLVideoElement>(null);

  // Auto-play on mount (some browsers require user gesture, 
  // but since it's muted it usually works).
  useEffect(() => {
    const vid = videoRef.current;
    if (vid) {
      vid.play().catch(() => {
        // fallback: if autoplay is blocked, wait 3s then redirect
        setTimeout(() => router.push('/hangout'), 3000);
      });
    }
  }, [router]);

  const handleEnded = () => {
    router.push('/hangout');
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'black',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <video
        ref={videoRef}
        src="/intro.mp4"
        muted
        autoPlay
        playsInline
        style={{
          maxWidth: '100%',
          maxHeight: '100%',
          objectFit: 'contain',
        }}
        onEnded={handleEnded}
      />
    </div>
  );
}
