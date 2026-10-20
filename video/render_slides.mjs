// Renders one PNG per lecture segment from build/lectures/<id>/manifest.json.
// Usage: node render_slides.mjs [courseId]
import { bundle } from '@remotion/bundler';
import { renderStill, selectComposition } from '@remotion/renderer';
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';

const root = resolve('../build/lectures');
const only = process.argv[2];
const serveUrl = await bundle({ entryPoint: resolve('src/index.ts') });
for (const id of readdirSync(root, { withFileTypes: true }).filter((d) => d.isDirectory()).map((d) => d.name)) {
  if (only && id !== only) continue;
  const m = JSON.parse(readFileSync(join(root, id, 'manifest.json'), 'utf8'));
  for (let i = 0; i < m.segments.length; i++) {
    const out = join(root, id, `slide${String(i).padStart(2, '0')}.png`);
    if (existsSync(out)) continue;
    const s = m.segments[i];
    const inputProps = { kind: s.kind, courseTitle: m.title, title: s.title, bullets: s.bullets, index: i, total: m.segments.length };
    const comp = await selectComposition({ serveUrl, id: 'LectureSlide', inputProps });
    await renderStill({ composition: comp, serveUrl, output: out, inputProps, frame: 0 });
  }
  console.log('slides', id);
}
