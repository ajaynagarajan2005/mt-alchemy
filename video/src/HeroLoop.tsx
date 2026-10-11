import {AbsoluteFill, useCurrentFrame} from 'remotion';

export const LOOP_FRAMES = 240;
const TAU = Math.PI * 2;

export type Theme = 'light' | 'dark';

export const PALETTE = {
  light: {bg0: '#FCFCFC', bg1: '#F4F4F5', crimson: '#C8102E', deep: '#9E0C24', wisp: '#A1A1AA'},
  dark: {bg0: '#18181B', bg1: '#27272A', crimson: '#E0243F', deep: '#B5122B', wisp: '#52525B'},
};

type Blob = {
  cx: number;
  cy: number;
  rx: number;
  ry: number;
  color: 'crimson' | 'deep' | 'wisp';
  opacity: number;
  blur: number;
  phase: number; // radians
  driftX: number;
  driftY: number;
  rot: number; // base rotation deg
  rotAmp: number;
  breathe: number; // scale amplitude
  harmonic?: number; // integer multiple of the base loop frequency
};

// Most energy centre/right/top; lower-left kept calm and pale.
const BLOBS: Blob[] = [
  {cx: 1350, cy: 380, rx: 520, ry: 300, color: 'crimson' as const, opacity: 0.85, blur: 60, phase: 0, driftX: 110, driftY: 60, rot: -25, rotAmp: 10, breathe: 0.12},
  {cx: 1100, cy: 220, rx: 380, ry: 190, color: 'deep' as const, opacity: 0.8, blur: 50, phase: 1.3, driftX: 90, driftY: 50, rot: 20, rotAmp: 14, breathe: 0.15},
  {cx: 1640, cy: 640, rx: 360, ry: 240, color: 'crimson' as const, opacity: 0.7, blur: 70, phase: 2.4, driftX: 80, driftY: 90, rot: 35, rotAmp: 12, breathe: 0.1},
  {cx: 900, cy: 480, rx: 300, ry: 130, color: 'deep' as const, opacity: 0.55, blur: 55, phase: 3.6, driftX: 120, driftY: 70, rot: -10, rotAmp: 18, breathe: 0.18, harmonic: 2},
  {cx: 1500, cy: 150, rx: 300, ry: 120, color: 'wisp' as const, opacity: 0.55, blur: 40, phase: 4.2, driftX: 140, driftY: 40, rot: 8, rotAmp: 10, breathe: 0.1},
  {cx: 760, cy: 260, rx: 420, ry: 90, color: 'wisp' as const, opacity: 0.4, blur: 36, phase: 5.1, driftX: 160, driftY: 50, rot: -18, rotAmp: 12, breathe: 0.12, harmonic: 2},
  {cx: 1780, cy: 330, rx: 200, ry: 360, color: 'wisp' as const, opacity: 0.4, blur: 44, phase: 0.8, driftX: 60, driftY: 80, rot: 12, rotAmp: 8, breathe: 0.1},
  {cx: 1250, cy: 760, rx: 280, ry: 110, color: 'crimson' as const, opacity: 0.5, blur: 50, phase: 2.9, driftX: 100, driftY: 40, rot: -30, rotAmp: 14, breathe: 0.14, harmonic: 2},
  {cx: 300, cy: 880, rx: 380, ry: 120, color: 'wisp' as const, opacity: 0.22, blur: 60, phase: 1.9, driftX: 40, driftY: 20, rot: 5, rotAmp: 4, breathe: 0.06},
];

// Fine tendrils: thin curved strokes that sway and thicken periodically.
const TENDRILS = [
  {d: 'M 1000 120 C 1200 260, 1050 420, 1300 520 S 1600 640, 1700 880', w: 22, color: 'deep' as const, o: 0.55, phase: 0.5},
  {d: 'M 1400 40 C 1500 220, 1250 300, 1450 460 S 1800 520, 1850 760', w: 16, color: 'crimson' as const, o: 0.6, phase: 2.0},
  {d: 'M 800 200 C 980 300, 900 480, 1120 560 S 1300 760, 1220 1000', w: 14, color: 'wisp' as const, o: 0.5, phase: 3.7},
];

export const HeroLoop = ({theme = 'light'}: {theme?: Theme}) => {
  const P = PALETTE[theme];
  const frame = useCurrentFrame();
  // theta is periodic: frame 240 === frame 0.
  const theta = (TAU * frame) / LOOP_FRAMES;

  return (
    <AbsoluteFill>
      <svg width={1920} height={1080} viewBox="0 0 1920 1080" style={{display: 'block'}}>
        <defs>
          <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor={P.bg0} />
            <stop offset="1" stopColor={P.bg1} />
          </linearGradient>
          {/* Ink-in-water displacement; frequencies and scale oscillate periodically. */}
          <filter id="water" x="-10%" y="-10%" width="120%" height="120%" colorInterpolationFilters="sRGB">
            <feTurbulence
              type="fractalNoise"
              baseFrequency={`${0.0045 + 0.0008 * Math.sin(theta)} ${0.007 + 0.001 * Math.cos(theta)}`}
              numOctaves={3}
              seed={7}
              result="noise"
            />
            <feDisplacementMap in="SourceGraphic" in2="noise" scale={150 + 40 * Math.sin(theta + 1)} xChannelSelector="R" yChannelSelector="G" />
          </filter>
          {BLOBS.map((b, i) => (
            <filter key={i} id={`blur${i}`} x="-50%" y="-50%" width="200%" height="200%">
              <feGaussianBlur stdDeviation={b.blur + 12 * Math.sin(theta + b.phase)} />
            </filter>
          ))}
          <filter id="tendrilBlur" x="-20%" y="-20%" width="140%" height="140%">
            <feGaussianBlur stdDeviation="20" />
          </filter>
          <radialGradient id="calm" cx="0.12" cy="0.88" r="0.5">
            <stop offset="0" stopColor={P.bg0} stopOpacity="0.85" />
            <stop offset="1" stopColor={P.bg0} stopOpacity="0" />
          </radialGradient>
        </defs>
        <rect width="1920" height="1080" fill="url(#bg)" />
        <g filter="url(#water)">
          {BLOBS.map((b, i) => {
            const h = b.harmonic ?? 1;
            const a = h * theta + b.phase;
            const x = b.cx + b.driftX * Math.sin(a);
            const y = b.cy + b.driftY * Math.cos(a + 0.7);
            const rot = b.rot + b.rotAmp * Math.sin(a + 1);
            const s = 1 + b.breathe * Math.sin(a + 2);
            const o = b.opacity * (0.88 + 0.12 * Math.sin(a + 0.4));
            return (
              <g key={i} filter={`url(#blur${i})`} opacity={o}>
                <ellipse
                  cx={x}
                  cy={y}
                  rx={b.rx * s}
                  ry={b.ry * (2 - s)}
                  fill={P[b.color]}
                  transform={`rotate(${rot} ${x} ${y})`}
                />
              </g>
            );
          })}
          <g filter="url(#tendrilBlur)">
            {TENDRILS.map((t, i) => (
              <path
                key={i}
                d={t.d}
                fill="none"
                stroke={P[t.color]}
                strokeWidth={t.w * (1 + 0.35 * Math.sin(theta + t.phase))}
                strokeLinecap="round"
                opacity={t.o * (0.8 + 0.2 * Math.sin(theta + t.phase + 1))}
                transform={`translate(${40 * Math.sin(theta + t.phase)} ${25 * Math.cos(theta + t.phase)})`}
              />
            ))}
          </g>
        </g>
        {/* Keep the lower-left calm for the glass text panel. */}
        <rect width="1920" height="1080" fill="url(#calm)" />
      </svg>
    </AbsoluteFill>
  );
};
