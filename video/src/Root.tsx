import {Composition} from 'remotion';
import {HeroLoop, LOOP_FRAMES} from './HeroLoop';
import {ServicesLoop, SERVICES_FRAMES} from './ServicesLoop';
import {BrandIntro, INTRO_FRAMES} from './BrandIntro';

const common = {width: 1920, height: 1080, fps: 30} as const;

export const Root = () => (
  <>
    <Composition id="HeroLoop" component={HeroLoop} durationInFrames={LOOP_FRAMES} defaultProps={{theme: 'light' as const}} {...common} />
    <Composition id="HeroLoopDark" component={HeroLoop} durationInFrames={LOOP_FRAMES} defaultProps={{theme: 'dark' as const}} {...common} />
    <Composition id="ServicesLoop" component={ServicesLoop} durationInFrames={SERVICES_FRAMES} defaultProps={{theme: 'light' as const}} {...common} />
    <Composition id="ServicesLoopDark" component={ServicesLoop} durationInFrames={SERVICES_FRAMES} defaultProps={{theme: 'dark' as const}} {...common} />
    <Composition id="BrandIntro" component={BrandIntro} durationInFrames={INTRO_FRAMES} {...common} />
  </>
);
