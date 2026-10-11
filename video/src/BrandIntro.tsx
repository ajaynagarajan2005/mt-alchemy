import React from 'react';
import {AbsoluteFill, Easing, interpolate, useCurrentFrame} from 'remotion';
import {loadFont as loadFraunces} from '@remotion/google-fonts/Fraunces';
import {loadFont as loadManrope} from '@remotion/google-fonts/Manrope';
import {HeroLoop, PALETTE} from './HeroLoop';

export const INTRO_FRAMES = 420;
const {fontFamily: serif} = loadFraunces();
const {fontFamily: sans} = loadManrope();
const P = PALETTE.light;
const INK = '#18181B';

const ease = Easing.out(Easing.cubic);

// Fade in, hold, optionally fade out, with a slight upward drift on entry.
const reveal = (frame: number, inAt: number, inLen: number, outAt?: number, outLen = 20) => {
  const i = interpolate(frame, [inAt, inAt + inLen], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: ease});
  const o = outAt === undefined ? 1 : interpolate(frame, [outAt, outAt + outLen], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return {opacity: i * o, transform: `translateY(${(1 - i) * 28}px)`};
};

const center: React.CSSProperties = {
  position: 'absolute',
  left: 0,
  right: 0,
  textAlign: 'center',
  padding: '0 200px',
};

export const BrandIntro = () => {
  const frame = useCurrentFrame();
  const inkOpacity = interpolate(frame, [0, 120], [0, 0.5], {extrapolateRight: 'clamp', easing: ease});
  const inkScale = interpolate(frame, [0, INTRO_FRAMES], [1.12, 1]);

  return (
    <AbsoluteFill style={{backgroundColor: P.bg0}}>
      <AbsoluteFill style={{opacity: inkOpacity, transform: `scale(${inkScale})`}}>
        <HeroLoop />
      </AbsoluteFill>
      {/* Soft veil keeps type readable over the ink. */}
      <AbsoluteFill
        style={{background: `radial-gradient(ellipse 60% 50% at 50% 50%, ${P.bg0} 0%, ${P.bg0}cc 45%, ${P.bg0}00 100%)`, opacity: 0.9}}
      />
      <div style={{...center, top: 440, ...reveal(frame, 20, 40, 135)}}>
        <div style={{fontFamily: serif, fontWeight: 400, fontSize: 84, color: INK, letterSpacing: -1}}>We don't just run activities.</div>
      </div>
      <div style={{...center, top: 400, ...reveal(frame, 150, 40, 270)}}>
        <div style={{fontFamily: serif, fontWeight: 400, fontSize: 76, lineHeight: 1.2, color: INK, letterSpacing: -1}}>
          We shift mindsets, behaviours, and team culture.
        </div>
      </div>
      <div style={{...center, top: 410, ...reveal(frame, 290, 45)}}>
        <div style={{fontFamily: serif, fontWeight: 500, fontSize: 150, color: INK, letterSpacing: -3}}>
          <span style={{color: '#C8102E'}}>MT</span> Alchemy
        </div>
      </div>
      <div style={{...center, top: 625, ...reveal(frame, 330, 45)}}>
        <div style={{fontFamily: sans, fontWeight: 500, fontSize: 26, letterSpacing: 4, textTransform: 'uppercase', color: '#52525B'}}>
          Emotional Intelligence &nbsp;/&nbsp; Leadership &nbsp;/&nbsp; Team Engagement &nbsp;/&nbsp; Well-being
        </div>
      </div>
    </AbsoluteFill>
  );
};
