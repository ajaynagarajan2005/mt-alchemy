import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {PALETTE, Theme} from './HeroLoop';

export const SERVICES_FRAMES = 180;
const TAU = Math.PI * 2;

type Ribbon = {
  y: number; // base vertical position
  amp: number;
  width: number;
  color: 'crimson' | 'deep' | 'wisp';
  opacity: number;
  blur: number;
  phase: number;
  harmonic: number;
};

// Silk-like ribbons: soft thick bands crossing the frame, low contrast.
const RIBBONS: Ribbon[] = [
  {y: 330, amp: 120, width: 150, color: 'wisp', opacity: 0.35, blur: 34, phase: 0.0, harmonic: 1},
  {y: 520, amp: 150, width: 120, color: 'crimson', opacity: 0.28, blur: 40, phase: 1.4, harmonic: 1},
  {y: 700, amp: 110, width: 170, color: 'wisp', opacity: 0.3, blur: 38, phase: 2.6, harmonic: 1},
  {y: 430, amp: 90, width: 60, color: 'deep', opacity: 0.3, blur: 24, phase: 3.8, harmonic: 2},
  {y: 820, amp: 100, width: 90, color: 'crimson', opacity: 0.2, blur: 36, phase: 4.9, harmonic: 1},
];

const ribbonPath = (r: Ribbon, theta: number) => {
  const a = r.harmonic * theta + r.phase;
  const y = (k: number) => r.y + r.amp * Math.sin(a + k);
  // Cubic path across the whole frame, control points oscillate periodically.
  return `M -200 ${y(0)} C 300 ${y(1.6) - 160}, 800 ${y(3.1) + 180}, 1300 ${y(4.4)} S 1900 ${y(5.5) - 120}, 2200 ${y(2.2)}`;
};

export const ServicesLoop = ({theme = 'light'}: {theme?: Theme}) => {
  const P = PALETTE[theme];
  const frame = useCurrentFrame();
  const theta = (TAU * frame) / SERVICES_FRAMES;

  return (
    <AbsoluteFill>
      <svg width={1920} height={1080} viewBox="0 0 1920 1080" style={{display: 'block'}}>
        <defs>
          <linearGradient id="sbg" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor={P.bg0} />
            <stop offset="1" stopColor={P.bg1} />
          </linearGradient>
          <filter id="silk" x="-10%" y="-30%" width="120%" height="160%">
            <feTurbulence
              type="fractalNoise"
              baseFrequency={`${0.003 + 0.0005 * Math.sin(theta)} ${0.005 + 0.0007 * Math.cos(theta)}`}
              numOctaves={2}
              seed={11}
              result="n"
            />
            <feDisplacementMap in="SourceGraphic" in2="n" scale={90 + 25 * Math.sin(theta + 0.5)} xChannelSelector="R" yChannelSelector="G" />
          </filter>
          {RIBBONS.map((r, i) => (
            <filter key={i} id={`rb${i}`} x="-10%" y="-60%" width="120%" height="220%">
              <feGaussianBlur stdDeviation={r.blur + 6 * Math.sin(theta + r.phase)} />
            </filter>
          ))}
          <linearGradient id="calmL" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0" stopColor={P.bg0} stopOpacity="0.92" />
            <stop offset="0.5" stopColor={P.bg0} stopOpacity="0.8" />
            <stop offset="0.7" stopColor={P.bg0} stopOpacity="0" />
          </linearGradient>
        </defs>
        <rect width="1920" height="1080" fill="url(#sbg)" />
        <g filter="url(#silk)">
          {RIBBONS.map((r, i) => (
            <g key={i} filter={`url(#rb${i})`} opacity={r.opacity * (0.85 + 0.15 * Math.sin(theta * r.harmonic + r.phase + 1))}>
              <path
                d={ribbonPath(r, theta)}
                fill="none"
                stroke={P[r.color]}
                strokeWidth={r.width * (1 + 0.3 * Math.sin(theta + r.phase + 2))}
                strokeLinecap="round"
              />
            </g>
          ))}
        </g>
        {/* Keep the left 55% calmer for text in a glass panel. */}
        <rect width="1920" height="1080" fill="url(#calmL)" />
      </svg>
    </AbsoluteFill>
  );
};
