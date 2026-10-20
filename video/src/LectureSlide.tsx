import React from 'react';
import {AbsoluteFill} from 'remotion';
import {loadFont as loadFraunces} from '@remotion/google-fonts/Fraunces';
import {loadFont as loadManrope} from '@remotion/google-fonts/Manrope';

const {fontFamily: serif} = loadFraunces();
const {fontFamily: sans} = loadManrope();

const BLUE = '#1B2A78';
const PURPLE = '#6A3DB8';
const YELLOW = '#FFD95A';
const INK = '#141836';
const MUTED = '#4A4F73';

export type LectureSlideProps = {
  kind: 'title' | 'slide' | 'outro';
  courseTitle: string;
  title: string;
  bullets: string[];
  index: number;
  total: number;
};

export const lectureSlideDefaults: LectureSlideProps = {
  kind: 'slide',
  courseTitle: 'Emotional Intelligence Foundations',
  title: 'The ninety second pause',
  bullets: ['Breathe', 'Name the feeling', 'Decide the next useful step'],
  index: 5,
  total: 10,
};

export const LectureSlide: React.FC<LectureSlideProps> = ({kind, courseTitle, title, bullets, index, total}) => {
  const isTitle = kind === 'title';
  return (
    <AbsoluteFill style={{background: '#FAFBFF'}}>
      <div style={{position: 'absolute', width: 800, height: 800, borderRadius: '50%', left: -260, top: -300, background: 'radial-gradient(circle, #E8EBFA 0%, #fff0 70%)'}} />
      <div style={{position: 'absolute', width: 700, height: 700, borderRadius: '50%', right: -220, bottom: -260, background: 'radial-gradient(circle, #EDE6FA 0%, #fff0 70%)'}} />
      {/* progress along the top */}
      <div style={{position: 'absolute', left: 0, top: 0, height: 8, width: `${((index + 1) / total) * 100}%`, background: `linear-gradient(90deg, ${BLUE}, ${PURPLE})`}} />

      <div style={{position: 'absolute', left: 90, top: 56, fontFamily: sans, fontWeight: 800, fontSize: 20, letterSpacing: 4, textTransform: 'uppercase', color: PURPLE}}>
        {courseTitle}
      </div>

      <div style={{position: 'absolute', left: 90, right: 110, top: isTitle ? 220 : 130}}>
        <div style={{fontFamily: serif, fontWeight: 500, fontSize: isTitle ? 82 : 64, lineHeight: 1.1, letterSpacing: -1.5, color: INK, maxWidth: 1000}}>{title}</div>
        <div style={{marginTop: isTitle ? 36 : 44}}>
          {bullets.map((b, i) => (
            <div key={i} style={{display: 'flex', alignItems: 'flex-start', gap: 24, marginTop: i === 0 ? 0 : 22}}>
              <div style={{flex: 'none', width: 14, height: 14, marginTop: isTitle ? 18 : 17, borderRadius: 7, background: i % 2 === 0 ? BLUE : PURPLE}} />
              <div style={{fontFamily: sans, fontWeight: 600, fontSize: isTitle ? 36 : 40, lineHeight: 1.25, color: isTitle ? MUTED : INK, maxWidth: 980}}>{b}</div>
            </div>
          ))}
        </div>
      </div>

      {/* crystal */}
      <svg style={{position: 'absolute', right: 70, bottom: 70, width: 120, height: 152}} viewBox="-80 -140 160 240">
        <defs>
          <linearGradient id="lc" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor="#8F7AE0" />
            <stop offset="1" stopColor={BLUE} />
          </linearGradient>
        </defs>
        <polygon points="0,-128 62,-80 68,12 0,88 -68,12 -62,-80" fill="url(#lc)" stroke="#fff" strokeWidth={5} strokeLinejoin="round" />
        <polygon points="0,-128 -62,-80 0,-40" fill="#fff" opacity={0.32} />
        <polygon points="68,12 0,88 0,40" fill="#000" opacity={0.18} />
      </svg>
      <div style={{position: 'absolute', left: 90, bottom: 52, fontFamily: serif, fontSize: 30, color: INK}}>
        <span style={{color: BLUE}}>MT</span> Alchemy
      </div>
      <div style={{position: 'absolute', left: 300, bottom: 58, fontFamily: sans, fontWeight: 600, fontSize: 20, color: MUTED}}>
        {index + 1} of {total}
      </div>
      <div style={{position: 'absolute', right: 230, bottom: 70, width: 18, height: 18, borderRadius: 9, background: YELLOW}} />
    </AbsoluteFill>
  );
};
