import {Composition} from 'remotion';
import {HeroLoop, LOOP_FRAMES} from './HeroLoop';

export const Root = () => (
  <Composition
    id="HeroLoop"
    component={HeroLoop}
    width={1920}
    height={1080}
    fps={30}
    durationInFrames={LOOP_FRAMES}
  />
);
