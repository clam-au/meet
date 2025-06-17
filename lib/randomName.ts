// lib/randomName.ts
const ADJECTIVES = [
  'stupid','sneaky','jolly','wacky','slinky','goofy','saucy','bouncy','clammy','zippy',
];
const NOUNS = [
  'clamhead','slimyclam','clam','wetclam','sloppyclam','meanclam','manclam',
];

export function randomName() {
  const a = ADJECTIVES[Math.floor(Math.random()*ADJECTIVES.length)];
  const n = NOUNS[Math.floor(Math.random()*NOUNS.length)];
  return `${a}-${n}`;
}
