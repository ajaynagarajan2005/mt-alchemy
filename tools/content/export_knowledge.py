"""Writes assets/data/course_knowledge.json: the passages the in-app assistant
searches when someone asks a question about a course.
Run from the repo root: python -m tools.content.export_knowledge"""
import json, os
from .all_courses import COURSES

out = {}
for cid, c in COURSES.items():
    passages = []
    for i, (title, bullets, narration) in enumerate(c['slides']):
        passages.append(dict(id='%s-s%d' % (cid, i), title='Lecture: ' + title,
                             text=' '.join(bullets) + '. ' + narration))
    for i, (term, d) in enumerate(c['glossary']):
        passages.append(dict(id='%s-g%d' % (cid, i), title='Glossary: ' + term, text='%s: %s' % (term, d)))
    et, steps = c['exercise']
    passages.append(dict(id='%s-ex' % cid, title='Exercise: ' + et, text=' '.join(steps)))
    passages.append(dict(id='%s-rq' % cid, title='Reflection questions', text=' '.join(c['reflect'])))
    out[cid] = passages
os.makedirs('assets/data', exist_ok=True)
json.dump(out, open('assets/data/course_knowledge.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
print(sum(len(v) for v in out.values()), 'passages')
