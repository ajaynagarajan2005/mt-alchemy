import {Composition} from 'remotion';
import {HeroLoop, LOOP_FRAMES} from './HeroLoop';
import {ServicesLoop, SERVICES_FRAMES} from './ServicesLoop';
import {BrandIntro, INTRO_FRAMES} from './BrandIntro';
import {SiteTour, TOUR_FRAMES} from './SiteTour';
import {CourseExplainer, COURSE_FRAMES, courseExplainerDefaults} from './CourseExplainer';

const common = {width: 1920, height: 1080, fps: 30} as const;

export const Root = () => (
  <>
    <Composition id="HeroLoop" component={HeroLoop} durationInFrames={LOOP_FRAMES} defaultProps={{theme: 'light' as const}} {...common} />
    <Composition id="HeroLoopDark" component={HeroLoop} durationInFrames={LOOP_FRAMES} defaultProps={{theme: 'dark' as const}} {...common} />
    <Composition id="ServicesLoop" component={ServicesLoop} durationInFrames={SERVICES_FRAMES} defaultProps={{theme: 'light' as const}} {...common} />
    <Composition id="ServicesLoopDark" component={ServicesLoop} durationInFrames={SERVICES_FRAMES} defaultProps={{theme: 'dark' as const}} {...common} />
    <Composition id="SiteTour" component={SiteTour} durationInFrames={TOUR_FRAMES} width={1280} height={720} fps={30} />
    <Composition id="CourseExplainer" component={CourseExplainer} durationInFrames={COURSE_FRAMES} defaultProps={courseExplainerDefaults} width={1280} height={720} fps={30} />
    <Composition id="BrandIntro" component={BrandIntro} durationInFrames={INTRO_FRAMES} {...common} />
  </>
);
