"""Writes build/lectures/<id>/manifest.json for the lecture pipeline.
Run from the repo root: python -m tools.content.build_manifest"""
import json, os
from .all_courses import COURSES

seed = json.load(open('tools/seed/seed.json', encoding='utf-8'))['courses']
out_root = os.path.join('build', 'lectures')

for cid, c in COURSES.items():
    meta = seed[cid]
    title, trainer, outcomes = meta['title'], meta['trainer'], meta['outcomes']
    segs = [dict(kind='title', title=title, bullets=['Full video lecture', 'With ' + trainer],
                 narration=("Welcome. This is the full video lecture for %s, led by %s. It walks through the main ideas "
                            "from all three phases of the course, so that you can see how they fit together before you "
                            "work through the individual lessons. You can pause or replay any part whenever you need to. "
                            "After the lecture, open the study materials for this course. They include a study guide, "
                            "a practice workbook and a quick reference card.") % (title, trainer))]
    for t, b, n in c['slides']:
        segs.append(dict(kind='slide', title=t, bullets=b, narration=n))
    segs.append(dict(kind='outro', title='What you should now be able to do', bullets=outcomes,
                     narration=("To recap, by the end of this course you should be able to do three things. First, %s. "
                                "Second, %s. And third, %s. Take your time with the lessons and the quizzes, and use the "
                                "workbook to practise. When you finish the final lesson, you will receive your "
                                "certificate. Thank you for watching.") % (outcomes[0].lower(), outcomes[1].lower(), outcomes[2].lower())))
    d = os.path.join(out_root, cid)
    os.makedirs(d, exist_ok=True)
    json.dump(dict(id=cid, title=title, trainer=trainer, segments=segs), open(os.path.join(d, 'manifest.json'), 'w', encoding='utf-8'), indent=1)
    words = sum(len(s['narration'].split()) for s in segs)
    print(cid, 'segments', len(segs), 'words', words)
