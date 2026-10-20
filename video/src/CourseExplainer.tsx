import React from 'react';
import {AbsoluteFill, Easing, interpolate, useCurrentFrame} from 'remotion';
import {loadFont as loadFraunces} from '@remotion/google-fonts/Fraunces';
import {loadFont as loadManrope} from '@remotion/google-fonts/Manrope';

export const COURSE_FRAMES = 300;
const {fontFamily: serif} = loadFraunces();
const {fontFamily: sans} = loadManrope();

const RED = '#1B2A78';
const DEEP = '#111C55';
const INK = '#141836';
const MUTED = '#4A4F73';
const ASH = '#EEF0F8';
const SOFT = '#E8EBFA';

export type CourseExplainerProps = {
  kind: 'intro' | 'recap';
  title: string;
  trainer: string;
  level: string;
  area: string;
  outcomes: string[];
  phases: {name: string; count: number}[];
};

export const courseExplainerDefaults: CourseExplainerProps = {
  kind: 'intro',
  title: 'Emotional Intelligence Foundations',
  trainer: 'Maya Thompson',
  level: 'Foundation',
  area: 'Emotional Intelligence',
  outcomes: ['Recognise your own emotional patterns', 'Use a simple pause routine under pressure', 'Read the room in meetings more accurately'],
  phases: [
    {name: 'Orientation', count: 3},
    {name: 'Core skills', count: 4},
    {name: 'Put it to work', count: 3},
  ],
};

const ease = Easing.out(Easing.cubic);
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

// Fade and rise in at `at`, fade out at `out` (optional).
const show = (f: number, at: number, out?: number) => {
  const i = interpolate(f, [at, at + 24], [0, 1], {...clamp, easing: ease});
  const o = out === undefined ? 1 : interpolate(f, [out, out + 18], [1, 0], clamp);
  return {opacity: i * o, transform: `translateY(${(1 - i) * 26}px)`};
};

const Crystal: React.FC<{x: number; y: number; s: number; f: number}> = ({x, y, s, f}) => (
  <svg style={{position: 'absolute', left: x, top: y + Math.sin(f / 18) * 8, width: 150 * s, height: 190 * s}} viewBox="-80 -140 160 240">
    <defs>
      <linearGradient id="cx" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#8F7AE0" />
        <stop offset="1" stopColor={RED} />
      </linearGradient>
    </defs>
    <polygon points="0,-128 62,-80 68,12 0,88 -68,12 -62,-80" fill="url(#cx)" stroke="#fff" strokeWidth={5} strokeLinejoin="round" />
    <polygon points="0,-128 -62,-80 0,-40" fill="#fff" opacity={0.32} />
    <polygon points="62,-80 68,12 0,-40" fill={DEEP} opacity={0.22} />
    <polygon points="68,12 0,88 0,40" fill={DEEP} opacity={0.34} />
  </svg>
);

const Background: React.FC<{f: number}> = ({f}) => (
  <AbsoluteFill style={{background: '#FAFBFF'}}>
    <div style={{position: 'absolute', width: 760, height: 760, borderRadius: '50%', left: -200 + Math.sin(f / 60) * 20, top: -260, background: `radial-gradient(circle, ${SOFT} 0%, #fff0 70%)`}} />
    <div style={{position: 'absolute', width: 640, height: 640, borderRadius: '50%', right: -180, bottom: -240 + Math.cos(f / 70) * 20, background: `radial-gradient(circle, ${ASH} 0%, #fff0 70%)`}} />
    <div style={{position: 'absolute', left: 0, top: 0, height: 8, width: `${(f / COURSE_FRAMES) * 100}%`, background: RED}} />
  </AbsoluteFill>
);

const pad: React.CSSProperties = {position: 'absolute', left: 96, right: 96};

const Eyebrow: React.FC<{children: React.ReactNode; style?: React.CSSProperties}> = ({children, style}) => (
  <div style={{fontFamily: sans, fontWeight: 800, fontSize: 22, letterSpacing: 5, textTransform: 'uppercase', color: RED, ...style}}>{children}</div>
);

const Intro: React.FC<{p: CourseExplainerProps; f: number}> = ({p, f}) => (
  <>
    {/* Scene 1: title */}
    <div style={{...pad, top: 190, ...show(f, 6, 92)}}>
      <Eyebrow>{p.area} · {p.level}</Eyebrow>
      <div style={{fontFamily: serif, fontWeight: 500, fontSize: 84, lineHeight: 1.08, color: INK, letterSpacing: -2, marginTop: 24, maxWidth: 900}}>{p.title}</div>
      <div style={{fontFamily: sans, fontSize: 32, color: MUTED, marginTop: 28}}>with {p.trainer}</div>
    </div>
    {/* Scene 2: outcomes */}
    <div style={{...pad, top: 130, ...show(f, 100, 200)}}>
      <Eyebrow>What you will learn</Eyebrow>
      {p.outcomes.map((o, i) => (
        <div key={i} style={{display: 'flex', alignItems: 'center', gap: 28, marginTop: 40, ...show(f, 112 + i * 16, 200)}}>
          <div style={{width: 64, height: 64, borderRadius: 32, background: RED, color: '#fff', fontFamily: serif, fontSize: 34, display: 'flex', alignItems: 'center', justifyContent: 'center', flex: 'none'}}>{i + 1}</div>
          <div style={{fontFamily: serif, fontSize: 44, lineHeight: 1.15, color: INK, maxWidth: 860}}>{o}</div>
        </div>
      ))}
    </div>
    {/* Scene 3: phases */}
    <div style={{...pad, top: 130, ...show(f, 210)}}>
      <Eyebrow>How the course works</Eyebrow>
      <div style={{fontFamily: serif, fontSize: 52, color: INK, marginTop: 20}}>Three phases, one step at a time</div>
      <div style={{display: 'flex', gap: 28, marginTop: 44}}>
        {p.phases.map((ph, i) => (
          <div key={i} style={{flex: 1, background: '#fff', border: `2px solid ${i === 0 ? RED : '#DFE2F0'}`, borderRadius: 24, padding: '30px 28px', ...show(f, 224 + i * 14)}}>
            <div style={{fontFamily: sans, fontWeight: 800, fontSize: 20, color: RED, letterSpacing: 3}}>PHASE {i + 1}</div>
            <div style={{fontFamily: serif, fontSize: 38, color: INK, marginTop: 10}}>{ph.name}</div>
            <div style={{fontFamily: sans, fontSize: 24, color: MUTED, marginTop: 10}}>{ph.count} lessons</div>
          </div>
        ))}
      </div>
      <div style={{fontFamily: sans, fontSize: 28, color: MUTED, marginTop: 36}}>Videos, readings and quizzes. Finish them all to earn your certificate.</div>
    </div>
  </>
);

const Recap: React.FC<{p: CourseExplainerProps; f: number}> = ({p, f}) => (
  <>
    {/* Scene 1: what you covered */}
    <div style={{...pad, top: 130, ...show(f, 6, 108)}}>
      <Eyebrow>Recap · {p.title}</Eyebrow>
      <div style={{fontFamily: serif, fontSize: 56, color: INK, marginTop: 20}}>What you have covered</div>
      {p.outcomes.map((o, i) => {
        const t = interpolate(f, [30 + i * 18, 52 + i * 18], [0, 1], {...clamp, easing: ease});
        return (
          <div key={i} style={{display: 'flex', alignItems: 'center', gap: 28, marginTop: 36, ...show(f, 20 + i * 18, 108)}}>
            <svg width={64} height={64} viewBox="0 0 64 64" style={{flex: 'none'}}>
              <circle cx={32} cy={32} r={29} fill={SOFT} stroke={RED} strokeWidth={3} />
              <path d="M18 33 L28 43 L47 22" fill="none" stroke={RED} strokeWidth={6} strokeLinecap="round" strokeLinejoin="round" strokeDasharray={50} strokeDashoffset={50 * (1 - t)} />
            </svg>
            <div style={{fontFamily: serif, fontSize: 42, lineHeight: 1.15, color: INK, maxWidth: 880}}>{o}</div>
          </div>
        );
      })}
    </div>
    {/* Scene 2: take it into the week */}
    <div style={{...pad, top: 170, ...show(f, 118, 204)}}>
      <Eyebrow>Take it into your week</Eyebrow>
      <div style={{fontFamily: serif, fontSize: 60, lineHeight: 1.12, color: INK, marginTop: 24, maxWidth: 940}}>Pick one situation in the next seven days and try this:</div>
      <div style={{fontFamily: serif, fontSize: 46, color: RED, marginTop: 30, maxWidth: 940}}>{p.outcomes[0]}</div>
    </div>
    {/* Scene 3: finish */}
    <div style={{...pad, top: 210, ...show(f, 214)}}>
      <Eyebrow>Last step</Eyebrow>
      <div style={{fontFamily: serif, fontSize: 68, lineHeight: 1.1, color: INK, marginTop: 24, maxWidth: 860}}>Pass the final quiz and press Finish course.</div>
      <div style={{fontFamily: sans, fontSize: 30, color: MUTED, marginTop: 28}}>Your certificate and a personal review are written for you.</div>
    </div>
  </>
);

export const CourseExplainer: React.FC<CourseExplainerProps> = (props) => {
  const f = useCurrentFrame();
  const p = {...courseExplainerDefaults, ...props};
  return (
    <AbsoluteFill>
      <Background f={f} />
      {p.kind === 'intro' ? <Intro p={p} f={f} /> : <Recap p={p} f={f} />}
      <Crystal x={1080} y={520} s={0.95} f={f} />
      <div style={{position: 'absolute', left: 96, bottom: 44, fontFamily: serif, fontSize: 30, color: INK}}>
        <span style={{color: RED}}>MT</span> Alchemy
      </div>
    </AbsoluteFill>
  );
};
