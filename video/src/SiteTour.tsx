import React from 'react';
import {AbsoluteFill, Easing, Sequence, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {loadFont as loadFraunces} from '@remotion/google-fonts/Fraunces';
import {loadFont as loadManrope} from '@remotion/google-fonts/Manrope';

/**
 * "Virtual tour": a cartoon explainer for the MT Alchemy site.
 * Alchy, the crystal mascot, guides three friendly characters through
 * learning, the store, teams, trainers and the EQ check. All artwork is
 * drawn here in SVG, so there is nothing to license.
 */
const {fontFamily: serif} = loadFraunces();
const {fontFamily: sans} = loadManrope();

const RED = '#C8102E';
const DEEP = '#9E0C24';
const SOFT = '#FBE7EA';
const INK = '#18181B';
const ASH = '#E4E4E7';
const ASH2 = '#F4F4F5';
const SKIN = ['#F2C9A5', '#C68E65', '#8D5A3B'];

export const SCENES = [
  {id: 'intro', frames: 150},
  {id: 'learn', frames: 220},
  {id: 'shop', frames: 190},
  {id: 'teams', frames: 200},
  {id: 'experts', frames: 190},
  {id: 'eq', frames: 170},
  {id: 'outro', frames: 150},
];
export const TOUR_FRAMES = SCENES.reduce((a, s) => a + s.frames, 0);

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const easeOut = Easing.out(Easing.cubic);

const usePop = (delay = 0) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  return spring({frame: frame - delay, fps, config: {damping: 11, stiffness: 110, mass: 0.8}});
};

// ---------- Characters ----------

type PersonProps = {
  x: number;
  y: number;
  s?: number;
  skin?: string;
  hair?: string;
  top?: string;
  pants?: string;
  glasses?: boolean;
  longHair?: boolean;
  wave?: boolean;
  delay?: number;
  look?: number; // -1 left .. 1 right
};

const Person = ({x, y, s = 1, skin = SKIN[0], hair = '#2B2118', top = RED, pants = INK, glasses, longHair, wave, delay = 0, look = 0}: PersonProps) => {
  const frame = useCurrentFrame();
  const pop = usePop(delay);
  const bob = Math.sin((frame + delay * 3) / 14) * 3;
  const blink = frame % 96 < 4 ? 0.1 : 1;
  const rArm = wave ? -135 + Math.sin(frame / 5) * 22 : -(8 + Math.sin(frame / 18) * 4);
  return (
    <g transform={`translate(${x} ${y + (1 - pop) * 80}) scale(${s * pop})`} opacity={Math.min(1, pop * 1.4)}>
      <ellipse cx={0} cy={4} rx={58} ry={9} fill={INK} opacity={0.08} />
      <g transform={`translate(0 ${bob * 0.4})`}>
        <rect x={-24} y={-72} width={20} height={72} rx={8} fill={pants} />
        <rect x={4} y={-72} width={20} height={72} rx={8} fill={pants} />
        <rect x={-30} y={-6} width={28} height={12} rx={6} fill={INK} />
        <rect x={2} y={-6} width={28} height={12} rx={6} fill={INK} />
        {longHair && <rect x={-40} y={-232} width={80} height={90} rx={30} fill={hair} />}
        <rect x={-44} y={-176} width={88} height={112} rx={30} fill={top} />
        {/* arms */}
        <g transform={`translate(-44 -160) rotate(${8 - Math.sin(frame / 18) * 3})`}>
          <rect x={-12} y={0} width={18} height={78} rx={9} fill={top} />
          <circle cx={-3} cy={82} r={11} fill={skin} />
        </g>
        <g transform={`translate(44 -160) rotate(${rArm})`}>
          <rect x={-6} y={0} width={18} height={78} rx={9} fill={top} />
          <circle cx={3} cy={82} r={11} fill={skin} />
        </g>
        <rect x={-9} y={-186} width={18} height={20} rx={8} fill={skin} />
        <g transform={`translate(0 ${bob})`}>
          <circle cx={0} cy={-222} r={42} fill={hair} />
          <circle cx={0} cy={-214} r={36} fill={skin} />
          <path d={`M -36 -226 Q 0 -262 36 -226 Q 12 -240 -36 -226 Z`} fill={hair} />
          <g transform={`translate(${look * 3} 0)`}>
            <ellipse cx={-13} cy={-214} rx={4.5} ry={5 * blink} fill={INK} />
            <ellipse cx={13} cy={-214} rx={4.5} ry={5 * blink} fill={INK} />
            {glasses && (
              <g fill="none" stroke={INK} strokeWidth={3}>
                <circle cx={-13} cy={-214} r={11} />
                <circle cx={13} cy={-214} r={11} />
                <path d="M -2 -214 L 2 -214" />
              </g>
            )}
            <path d="M -11 -198 Q 0 -187 11 -198" fill="none" stroke={INK} strokeWidth={3.5} strokeLinecap="round" />
          </g>
          <circle cx={-24} cy={-203} r={6} fill={RED} opacity={0.18} />
          <circle cx={24} cy={-203} r={6} fill={RED} opacity={0.18} />
        </g>
      </g>
    </g>
  );
};

/** Alchy: the red glass-crystal mascot who narrates the tour. */
const Alchy = ({x, y, s = 1, delay = 0, wave = true}: {x: number; y: number; s?: number; delay?: number; wave?: boolean}) => {
  const frame = useCurrentFrame();
  const pop = usePop(delay);
  const float = Math.sin(frame / 16) * 9;
  const blink = frame % 110 < 4 ? 0.1 : 1;
  const arm = wave ? Math.sin(frame / 5) * 25 - 40 : 20;
  return (
    <g transform={`translate(${x} ${y + float + (1 - pop) * 60}) scale(${s * pop})`} opacity={Math.min(1, pop * 1.4)}>
      <ellipse cx={0} cy={86 - float * 0.4} rx={52 + float * 0.4} ry={9} fill={INK} opacity={0.1} />
      <defs>
        <linearGradient id="alchyBody" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#E0243F" />
          <stop offset="1" stopColor={DEEP} />
        </linearGradient>
      </defs>
      <g transform={`translate(-62 10) rotate(${-arm})`}>
        <rect x={-34} y={-8} width={40} height={16} rx={8} fill={RED} />
      </g>
      <g transform="translate(62 10) rotate(20)">
        <rect x={-6} y={-8} width={40} height={16} rx={8} fill={RED} />
      </g>
      {/* faceted crystal body */}
      <g strokeLinejoin="round">
        <polygon points="0,-128 62,-80 68,12 0,88 -68,12 -62,-80" fill="url(#alchyBody)" stroke="#fff" strokeOpacity={0.8} strokeWidth={5} />
        <polygon points="0,-128 -62,-80 0,-40" fill="#fff" opacity={0.32} />
        <polygon points="0,-128 62,-80 0,-40" fill="#fff" opacity={0.12} />
        <polygon points="-62,-80 -68,12 0,-40" fill="#fff" opacity={0.18} />
        <polygon points="62,-80 68,12 0,-40" fill={DEEP} opacity={0.22} />
        <polygon points="-68,12 0,88 0,40" fill={DEEP} opacity={0.18} />
        <polygon points="68,12 0,88 0,40" fill={DEEP} opacity={0.34} />
      </g>
      <polygon points="-44,-70 -26,-82 -34,-52" fill="#fff" opacity={0.7} />
      <g>
        <ellipse cx={-22} cy={8} rx={13} ry={15 * blink} fill="#fff" />
        <ellipse cx={22} cy={8} rx={13} ry={15 * blink} fill="#fff" />
        <circle cx={-20} cy={9} r={6.5} fill={INK} />
        <circle cx={24} cy={9} r={6.5} fill={INK} />
        <path d="M -16 36 Q 0 54 16 36" fill="none" stroke="#fff" strokeWidth={5} strokeLinecap="round" />
        <circle cx={-44} cy={30} r={8} fill="#fff" opacity={0.25} />
        <circle cx={44} cy={30} r={8} fill="#fff" opacity={0.25} />
      </g>
    </g>
  );
};

// ---------- Props ----------

const Card = ({x, y, w = 250, h = 190, children, delay = 0, rot = 0}: {x: number; y: number; w?: number; h?: number; children?: React.ReactNode; delay?: number; rot?: number}) => {
  const pop = usePop(delay);
  return (
    <g transform={`translate(${x} ${y + (1 - pop) * 50}) rotate(${rot}) scale(${pop})`} opacity={Math.min(1, pop * 1.5)}>
      <rect x={-w / 2 + 6} y={-h / 2 + 12} width={w} height={h} rx={22} fill={INK} opacity={0.08} />
      <rect x={-w / 2} y={-h / 2} width={w} height={h} rx={22} fill="#fff" stroke={ASH} strokeWidth={2} />
      {children}
    </g>
  );
};

/** A stylised course "photo": sky, sun and rolling hills. */
const Scenery = ({w, h, hue = RED}: {w: number; h: number; hue?: string}) => (
  <g>
    <clipPath id={`sc${w}${h}`}>
      <rect x={-w / 2} y={-h / 2} width={w} height={h} rx={20} />
    </clipPath>
    <g clipPath={`url(#sc${w}${h})`}>
      <rect x={-w / 2} y={-h / 2} width={w} height={h} fill={SOFT} />
      <circle cx={w / 4} cy={-h / 6} r={h / 5} fill="#fff" opacity={0.9} />
      <ellipse cx={-w / 5} cy={h / 2.2} rx={w / 1.4} ry={h / 2.4} fill={hue} opacity={0.85} />
      <ellipse cx={w / 3} cy={h / 2} rx={w / 1.6} ry={h / 2.8} fill={DEEP} opacity={0.8} />
    </g>
  </g>
);

const Bar = ({x, y, w, value, color = RED}: {x: number; y: number; w: number; value: number; color?: string}) => (
  <g transform={`translate(${x} ${y})`}>
    <rect width={w} height={14} rx={7} fill={ASH} />
    <rect width={Math.max(14, w * value)} height={14} rx={7} fill={color} />
  </g>
);

const Rosette = ({x, y, s = 1, delay = 0}: {x: number; y: number; s?: number; delay?: number}) => {
  const pop = usePop(delay);
  return (
    <g transform={`translate(${x} ${y}) scale(${s * pop}) rotate(${(1 - pop) * -40})`}>
      <path d="M -22 20 L -34 70 L -12 58 L 0 74 L 0 20 Z" fill={DEEP} />
      <path d="M 22 20 L 34 70 L 12 58 L 0 74 L 0 20 Z" fill={RED} />
      <circle r={44} fill={RED} stroke="#fff" strokeWidth={5} />
      <circle r={32} fill="none" stroke="#fff" strokeOpacity={0.6} strokeWidth={3} strokeDasharray="4 6" />
      <path d="M 0 -20 L 6 -6 L 21 -5 L 10 5 L 13 20 L 0 12 L -13 20 L -10 5 L -21 -5 L -6 -6 Z" fill="#fff" />
    </g>
  );
};

const Sparkles = ({x, y, delay = 0}: {x: number; y: number; delay?: number}) => {
  const frame = useCurrentFrame();
  return (
    <g transform={`translate(${x} ${y})`}>
      {[0, 1, 2, 3, 4, 5].map((i) => {
        const t = (frame - delay + i * 7) % 42;
        const a = (i / 6) * Math.PI * 2;
        const r = interpolate(t, [0, 42], [10, 90], clamp);
        return <circle key={i} cx={Math.cos(a) * r} cy={Math.sin(a) * r} r={interpolate(t, [0, 42], [7, 0], clamp)} fill={i % 2 ? RED : '#F5B3BE'} />;
      })}
    </g>
  );
};

// ---------- Scene furniture ----------

const Backdrop = ({tint = SOFT}: {tint?: string}) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill>
      <svg width={1280} height={720} viewBox="0 0 1280 720">
        <rect width={1280} height={720} fill="#fff" />
        <circle cx={1080 + Math.sin(frame / 60) * 20} cy={170} r={260} fill={tint} opacity={0.9} />
        <circle cx={160 + Math.cos(frame / 70) * 16} cy={560} r={200} fill={ASH2} />
        <circle cx={640} cy={760} r={420} fill={ASH2} opacity={0.7} />
        <rect x={0} y={560} width={1280} height={160} fill={ASH2} />
        {[0, 1, 2, 3, 4, 5].map((i) => (
          <circle key={i} cx={120 + i * 220 + Math.sin(frame / 40 + i) * 12} cy={90 + ((i * 53) % 90) + Math.cos(frame / 33 + i) * 10} r={5 + (i % 3) * 2} fill={RED} opacity={0.16} />
        ))}
      </svg>
    </AbsoluteFill>
  );
};

const Caption = ({lines, tag, delay = 14}: {lines: string[]; tag: string; delay?: number}) => {
  const frame = useCurrentFrame();
  const i = interpolate(frame, [delay, delay + 14], [0, 1], {...clamp, easing: easeOut});
  const tagIn = interpolate(frame, [4, 18], [0, 1], {...clamp, easing: easeOut});
  return (
    <>
      <div style={{position: 'absolute', left: 48, top: 40, opacity: tagIn, transform: `translateY(${(1 - tagIn) * -16}px)`, background: RED, color: '#fff', fontFamily: sans, fontWeight: 800, fontSize: 24, letterSpacing: 1.5, padding: '10px 22px', borderRadius: 40, textTransform: 'uppercase'}}>
        {tag}
      </div>
      <div style={{position: 'absolute', left: 64, right: 64, bottom: 36, opacity: i, transform: `translateY(${(1 - i) * 24}px)`, background: 'rgba(255,255,255,0.94)', border: `2px solid ${ASH}`, borderRadius: 28, padding: '20px 34px', boxShadow: '0 20px 50px rgba(24,24,27,0.12)'}}>
        {lines.map((l, k) => (
          <div key={k} style={{fontFamily: k === 0 ? serif : sans, fontSize: k === 0 ? 40 : 26, fontWeight: k === 0 ? 500 : 600, color: k === 0 ? INK : '#52525B', lineHeight: 1.3}}>
            {l}
          </div>
        ))}
      </div>
    </>
  );
};

const Scene = ({children, tag, lines, tint}: {children: React.ReactNode; tag: string; lines: string[]; tint?: string}) => {
  const frame = useCurrentFrame();
  const {durationInFrames} = useVideoConfig();
  const fade = Math.min(interpolate(frame, [0, 10], [0, 1], clamp), interpolate(frame, [durationInFrames - 10, durationInFrames], [1, 0], clamp));
  return (
    <AbsoluteFill style={{opacity: fade}}>
      <Backdrop tint={tint} />
      <svg width={1280} height={720} viewBox="0 0 1280 720" style={{position: 'absolute', inset: 0}}>
        {children}
      </svg>
      <Caption tag={tag} lines={lines} />
    </AbsoluteFill>
  );
};

// ---------- Scenes ----------

const Intro = () => {
  const frame = useCurrentFrame();
  const t = interpolate(frame, [20, 44], [0, 1], {...clamp, easing: easeOut});
  return (
    <AbsoluteFill style={{opacity: Math.min(1, interpolate(frame, [0, 8], [0, 1], clamp), interpolate(frame, [140, 150], [1, 0], clamp))}}>
      <Backdrop />
      <svg width={1280} height={720} viewBox="0 0 1280 720" style={{position: 'absolute', inset: 0}}>
        <Alchy x={640} y={330} s={1.35} />
        <Person x={250} y={560} s={1.05} delay={18} wave skin={SKIN[1]} top={RED} />
        <Person x={1030} y={560} s={1.05} delay={26} wave skin={SKIN[0]} top={INK} hair="#5A3A22" longHair />
        <Sparkles x={640} y={250} delay={40} />
      </svg>
      <div style={{position: 'absolute', left: 0, right: 0, top: 54, textAlign: 'center', opacity: t, transform: `translateY(${(1 - t) * -20}px)`}}>
        <div style={{fontFamily: sans, fontWeight: 800, fontSize: 24, letterSpacing: 4, color: RED}}>VIRTUAL TOUR</div>
        <div style={{fontFamily: serif, fontSize: 70, color: INK, lineHeight: 1.1}}>
          Welcome to <span style={{color: RED}}>MT</span> Alchemy
        </div>
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, bottom: 44, textAlign: 'center', opacity: interpolate(frame, [50, 68], [0, 1], clamp), fontFamily: sans, fontWeight: 600, fontSize: 30, color: '#52525B'}}>
        Hi! I am Alchy. Let me show you around.
      </div>
    </AbsoluteFill>
  );
};

const Learn = () => {
  const frame = useCurrentFrame();
  const progress = interpolate(frame, [70, 150], [0.05, 1], {...clamp, easing: easeOut});
  const done = frame > 150;
  return (
    <Scene tag="1 · Learn" lines={['Learn at your own pace', 'Pick courses for your career stage, watch, read, take the quiz, then earn a certificate.']}>
      <Person x={250} y={492} s={0.95} delay={6} skin={SKIN[1]} top={RED} look={1} />
      <Card x={600} y={262} w={290} h={262} delay={18}>
        <g transform="translate(0 -52)">
          <Scenery w={250} h={110} />
        </g>
        <rect x={-120} y={26} width={150} height={12} rx={6} fill={ASH} />
        <rect x={-120} y={48} width={100} height={10} rx={5} fill={ASH2} />
        <Bar x={-120} y={78} w={240} value={progress} />
        <text x={-120} y={116} fontFamily={sans} fontWeight={800} fontSize={20} fill={RED}>
          {Math.round(progress * 100)}% complete
        </text>
      </Card>
      <Card x={960} y={232} w={230} h={170} delay={34} rot={5}>
        <g transform="translate(0 -26)">
          <rect x={-72} y={-34} width={144} height={80} rx={14} fill={INK} />
          <path d="M -10 -14 L 22 6 L -10 26 Z" fill="#fff" />
        </g>
        <text x={-92} y={72} fontFamily={sans} fontWeight={800} fontSize={20} fill={INK}>Video · PDF · Quiz</text>
      </Card>
      {done && <Rosette x={960} y={420} s={1.15} delay={150} />}
      {done && <Sparkles x={960} y={420} delay={150} />}
      <Alchy x={1130} y={300} s={0.7} delay={30} wave={false} />
    </Scene>
  );
};

const Shop = () => {
  const frame = useCurrentFrame();
  const truckX = interpolate(frame, [70, 170], [-120, 720], {...clamp, easing: Easing.inOut(Easing.cubic)});
  return (
    <Scene tag="2 · Shop" lines={['A store that keeps the work going', 'Download toolkits instantly, or get card decks and books delivered and tracked.']}>
      {/* shelf of products */}
      {[
        {x: 300, c: RED, label: 'Toolkit'},
        {x: 520, c: INK, label: 'Cards'},
        {x: 740, c: DEEP, label: 'Book'},
      ].map((p, i) => (
        <Card key={p.label} x={p.x} y={190} w={170} h={200} delay={8 + i * 8} rot={i === 1 ? -3 : 2}>
          <rect x={-56} y={-72} width={112} height={110} rx={14} fill={p.c} />
          <rect x={-40} y={-52} width={70} height={10} rx={5} fill="#fff" opacity={0.8} />
          <rect x={-40} y={-34} width={44} height={8} rx={4} fill="#fff" opacity={0.5} />
          <text x={-52} y={74} fontFamily={sans} fontWeight={800} fontSize={20} fill={INK}>{p.label}</text>
        </Card>
      ))}
      {/* download tile */}
      <Card x={1020} y={190} w={170} h={200} delay={40} rot={-4}>
        <circle cy={-14} r={48} fill={SOFT} />
        <path d="M 0 -42 L 0 4 M -20 -16 L 0 6 L 20 -16" stroke={RED} strokeWidth={9} strokeLinecap="round" strokeLinejoin="round" fill="none" />
        <rect x={-34} y={20} width={68} height={9} rx={4.5} fill={RED} />
        <text x={-58} y={74} fontFamily={sans} fontWeight={800} fontSize={20} fill={INK}>Download</text>
      </Card>
      {/* road + truck */}
      <rect x={0} y={470} width={1280} height={18} fill={ASH} />
      {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
        <rect key={i} x={i * 180 + 40} y={477} width={80} height={4} rx={2} fill="#fff" />
      ))}
      <g transform={`translate(${truckX} 410)`}>
        <rect x={0} y={-90} width={150} height={96} rx={14} fill={RED} />
        <text x={22} y={-34} fontFamily={serif} fontSize={34} fill="#fff">MT</text>
        <path d="M 150 -62 L 206 -62 L 232 -28 L 232 6 L 150 6 Z" fill={DEEP} />
        <path d="M 168 -52 L 198 -52 L 216 -28 L 168 -28 Z" fill="#fff" opacity={0.8} />
        <circle cx={46} cy={10} r={20} fill={INK} /><circle cx={46} cy={10} r={8} fill="#fff" />
        <circle cx={190} cy={10} r={20} fill={INK} /><circle cx={190} cy={10} r={8} fill="#fff" />
      </g>
      <Person x={1130} y={496} s={0.85} delay={110} skin={SKIN[2]} top={INK} look={-1} wave />
      <Alchy x={130} y={420} s={0.62} delay={20} wave={false} />
    </Scene>
  );
};

const Teams = () => {
  const frame = useCurrentFrame();
  const bars = [0.45, 0.7, 0.55, 0.9];
  return (
    <Scene tag="3 · Teams" lines={['Grow your whole team', 'Employers buy seats, assign courses and watch progress live in simple charts.']}>
      <Person x={230} y={492} s={0.95} delay={6} skin={SKIN[0]} top={INK} pants="#3F3F46" glasses look={1} />
      <Card x={640} y={270} w={360} h={250} delay={16}>
        <text x={-150} y={-84} fontFamily={sans} fontWeight={800} fontSize={22} fill={INK}>Team progress</text>
        {bars.map((v, i) => {
          const h = interpolate(frame, [40 + i * 14, 80 + i * 14], [0, v * 130], {...clamp, easing: easeOut});
          return <rect key={i} x={-130 + i * 70} y={90 - h} width={44} height={h} rx={10} fill={i === 3 ? RED : '#F5B3BE'} />;
        })}
        <rect x={-146} y={92} width={292} height={4} rx={2} fill={ASH} />
      </Card>
      {/* little team with progress rings */}
      {[0, 1, 2, 3].map((i) => {
        const pct = interpolate(frame, [70 + i * 10, 150 + i * 10], [0, [0.5, 0.8, 0.65, 1][i]], clamp);
        return (
          <g key={i} transform={`translate(${900 + (i % 2) * 150} ${i < 2 ? 200 : 380})`}>
            <circle r={56} fill="#fff" stroke={ASH} strokeWidth={2} />
            <circle r={50} fill="none" stroke={ASH} strokeWidth={8} />
            <circle r={50} fill="none" stroke={RED} strokeWidth={8} strokeLinecap="round" strokeDasharray={`${pct * 314} 314`} transform="rotate(-90)" />
            <circle cy={-6} r={16} fill={SKIN[i % 3]} />
            <path d="M -24 30 Q 0 -4 24 30 Z" fill={[RED, INK, DEEP, '#3F3F46'][i]} />
          </g>
        );
      })}
      <Alchy x={1150} y={560} s={0.55} delay={26} wave={false} />
    </Scene>
  );
};

const Experts = () => {
  const frame = useCurrentFrame();
  const items = ['Add video lessons', 'Write a quiz', 'Welcome learners free'];
  return (
    <Scene tag="4 · Trainers & admins" lines={['Easy for the people who run it', 'Trainers build courses. Admins see who joined and paid, and can add people free.']}>
      <Person x={1030} y={496} s={0.95} delay={6} skin={SKIN[2]} top={RED} longHair hair="#111" look={-1} />
      <Card x={430} y={290} w={420} h={260} delay={12}>
        <text x={-170} y={-96} fontFamily={sans} fontWeight={800} fontSize={24} fill={INK}>Course builder</text>
        {items.map((t, i) => {
          const on = frame > 50 + i * 40;
          const pop = interpolate(frame, [50 + i * 40, 62 + i * 40], [0, 1], {...clamp, easing: easeOut});
          return (
            <g key={t} transform={`translate(-170 ${-40 + i * 56})`}>
              <rect width={34} height={34} rx={9} fill={on ? RED : '#fff'} stroke={on ? RED : ASH} strokeWidth={3} />
              {on && <path d="M 8 18 L 15 25 L 27 11" stroke="#fff" strokeWidth={5} fill="none" strokeLinecap="round" strokeLinejoin="round" opacity={pop} />}
              <text x={52} y={26} fontFamily={sans} fontWeight={700} fontSize={26} fill={INK}>{t}</text>
            </g>
          );
        })}
      </Card>
      <Card x={800} y={250} w={190} h={150} delay={30} rot={6}>
        <text x={-70} y={-24} fontFamily={serif} fontSize={44} fill={RED}>128</text>
        <text x={-70} y={10} fontFamily={sans} fontWeight={700} fontSize={20} fill="#52525B">students</text>
        <Bar x={-70} y={34} w={140} value={interpolate(frame, [60, 120], [0.1, 0.85], clamp)} />
      </Card>
      <Alchy x={160} y={470} s={0.62} delay={22} wave={false} />
    </Scene>
  );
};

const Eq = () => {
  const frame = useCurrentFrame();
  const labels = ['Self-awareness', 'Empathy', 'Social skill'];
  return (
    <Scene tag="5 · Know yourself" lines={['Take the free EQ check', 'Five minutes, a friendly profile, and a course picked to help you grow.']}>
      <Person x={260} y={496} s={0.95} delay={6} skin={SKIN[0]} top={DEEP} longHair hair="#5A3A22" look={1} />
      <Card x={680} y={280} w={380} h={250} delay={16}>
        {labels.map((l, i) => (
          <g key={l} transform={`translate(-150 ${-62 + i * 62})`}>
            <text y={-6} fontFamily={sans} fontWeight={800} fontSize={20} fill={INK}>{l}</text>
            <Bar x={0} y={4} w={300} value={interpolate(frame, [50 + i * 16, 110 + i * 16], [0.05, [0.75, 0.9, 0.6][i]], {...clamp, easing: easeOut})} />
          </g>
        ))}
      </Card>
      {/* heart bubble from Alchy */}
      <g transform={`translate(1040 ${200 + Math.sin(frame / 12) * 8})`}>
        <ellipse rx={74} ry={56} fill="#fff" stroke={ASH} strokeWidth={3} />
        <path d="M 0 22 C -44 -4 -26 -42 0 -20 C 26 -42 44 -4 0 22 Z" fill={RED} />
      </g>
      <Alchy x={1060} y={390} s={0.7} delay={26} wave={false} />
    </Scene>
  );
};

const Outro = () => {
  const frame = useCurrentFrame();
  const t = interpolate(frame, [14, 40], [0, 1], {...clamp, easing: easeOut});
  const cells = Array.from({length: 49}, (_, i) => ((i * 37 + 11) % 5 < 2 ? 1 : 0));
  return (
    <AbsoluteFill style={{opacity: Math.min(interpolate(frame, [0, 10], [0, 1], clamp), interpolate(frame, [140, 150], [1, 0], clamp))}}>
      <Backdrop />
      <svg width={1280} height={720} viewBox="0 0 1280 720" style={{position: 'absolute', inset: 0}}>
        <Person x={210} y={560} delay={4} wave skin={SKIN[1]} top={RED} />
        <Person x={1070} y={560} delay={10} wave skin={SKIN[2]} top={INK} glasses />
        <Alchy x={640} y={330} s={0.9} delay={0} />
        <g transform={`translate(640 ${566 + (1 - t) * 40}) scale(${0.8 + 0.2 * t})`} opacity={t}>
          <rect x={-78} y={-78} width={156} height={156} rx={20} fill="#fff" stroke={ASH} strokeWidth={3} />
          {cells.map((c, i) => c ? <rect key={i} x={-60 + (i % 7) * 17} y={-60 + Math.floor(i / 7) * 17} width={14} height={14} rx={3} fill={INK} /> : null)}
          {[[-60, -60], [28, -60], [-60, 28]].map(([x, y], i) => (
            <g key={i} transform={`translate(${x} ${y})`}>
              <rect width={34} height={34} rx={6} fill={RED} />
              <rect x={8} y={8} width={18} height={18} rx={3} fill="#fff" />
            </g>
          ))}
        </g>
      </svg>
      <div style={{position: 'absolute', left: 0, right: 0, top: 54, textAlign: 'center', opacity: t}}>
        <div style={{fontFamily: serif, fontSize: 62, color: INK}}>Ready to <span style={{color: RED}}>shift</span> mindsets?</div>
        <div style={{fontFamily: sans, fontWeight: 700, fontSize: 28, color: '#52525B', marginTop: 10}}>Create a free account and start your journey.</div>
      </div>
    </AbsoluteFill>
  );
};

export const SiteTour = () => {
  let at = 0;
  const parts = [Intro, Learn, Shop, Teams, Experts, Eq, Outro];
  return (
    <AbsoluteFill style={{background: '#fff'}}>
      {SCENES.map((s, i) => {
        const Part = parts[i];
        const from = at;
        at += s.frames;
        return (
          <Sequence key={s.id} from={from} durationInFrames={s.frames}>
            <Part />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
