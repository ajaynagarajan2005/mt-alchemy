// Renders an intro and a recap film for every course in courses.json
// (written by `dart run tools/export_seed.dart`).
// Usage: node render_courses.mjs [courseId]
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { spawnSync } from 'node:child_process';

const only = process.argv[2];
const courses = JSON.parse(readFileSync(new URL('./courses.json', import.meta.url), 'utf8'));
mkdirSync(new URL('../assets/videos/courses/', import.meta.url), { recursive: true });
for (const c of courses) {
  if (only && c.id !== only) continue;
  for (const kind of ['intro', 'recap']) {
    const out = new URL(`../assets/videos/courses/${c.id}-${kind}.mp4`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
    const props = new URL(`./.props-${c.id}-${kind}.json`, import.meta.url);
    writeFileSync(props, JSON.stringify({ kind, title: c.title, trainer: c.trainer, level: c.level, area: c.area, outcomes: c.outcomes, phases: c.phases }));
    console.log('render', c.id, kind);
    const r = spawnSync('npx', ['remotion', 'render', 'src/index.ts', 'CourseExplainer', out, '--codec=h264', '--muted', '--crf=30', `--props=${props.pathname.replace(/^\/([A-Za-z]:)/, '$1')}`], { stdio: 'inherit', shell: true });
    if (r.status !== 0) process.exit(r.status ?? 1);
  }
}
