"""Generates the branded PDF workbooks served from web/downloads/.
Run: python tools/make_pdfs.py  (no third-party packages needed)."""
import json, os, textwrap

import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from tools.content.pdfwriter import pdf
from tools.content.study_pdfs import build_course_pdfs

seed = json.load(open('tools/seed/seed.json', encoding='utf-8'))
os.makedirs('web/downloads', exist_ok=True)
build_course_pdfs(seed)
for pid, p in seed['products'].items():
    if p['type'] != 'digital': continue
    secs = [('Welcome', [p['description']]), ("What's inside", ['- ' + d for d in p['details']])]
    for w in range(1, 7):
        secs.append(('Week %d practice' % w, ['Notice: when did you feel pulled off balance this week?', 'Name: what was the feeling, in one word?', 'Choose: what would a useful next step have been?', 'Repeat the pause routine once a day and tick each day you manage it.']))
    pdf('web/downloads/%s.pdf' % pid, p['name'], 'MT Alchemy digital product  |  Licensed to the purchaser', secs)
print('\n'.join(sorted(os.listdir('web/downloads'))))
