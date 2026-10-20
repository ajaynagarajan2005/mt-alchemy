#!/usr/bin/env bash
# Re-renders every film and poster after a palette change.
set -e
cd "$(dirname "$0")"
R="npx remotion render src/index.ts"
$R HeroLoop ../assets/videos/hero_loop.mp4 --codec=h264 --muted --crf=30
$R HeroLoopDark ../assets/videos/hero_loop_dark.mp4 --codec=h264 --muted --crf=30
$R ServicesLoop ../assets/videos/services_loop.mp4 --codec=h264 --muted --crf=30
$R ServicesLoopDark ../assets/videos/services_loop_dark.mp4 --codec=h264 --muted --crf=30
$R BrandIntro ../assets/videos/brand_intro.mp4 --codec=h264 --muted --crf=28
$R SiteTour ../assets/videos/site_tour.mp4 --codec=h264 --muted --crf=27
S="npx remotion still src/index.ts"
$S HeroLoop ../assets/images/hero_poster.jpg --frame=0 --image-format=jpeg --jpeg-quality=85
$S HeroLoopDark ../assets/images/hero_poster_dark.jpg --frame=0 --image-format=jpeg --jpeg-quality=85
$S ServicesLoop ../assets/images/services_poster.jpg --frame=0 --image-format=jpeg --jpeg-quality=85
$S ServicesLoopDark ../assets/images/services_poster_dark.jpg --frame=0 --image-format=jpeg --jpeg-quality=85
$S BrandIntro ../assets/images/brand_intro_poster.jpg --frame=330 --image-format=jpeg --jpeg-quality=85
$S SiteTour ../assets/images/tour_poster.jpg --frame=300 --image-format=jpeg --jpeg-quality=85
node render_courses.mjs
echo ALL_DONE
