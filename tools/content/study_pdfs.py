"""Builds three PDFs for every course into web/downloads/:
  <id>-study-guide.pdf      the lecture as notes, with the glossary
  <id>-workbook.pdf         reflection questions, an exercise and an action plan
  <id>-quick-reference.pdf  a one-page summary to keep nearby
"""
from .all_courses import COURSES
from .pdfwriter import pdf


def _clean(text):
    """The writer is latin-1 only; keep to plain punctuation."""
    return (text.replace('’', "'").replace('‘', "'").replace('“', '"')
            .replace('”', '"').replace('–', '-').replace('—', '-'))


def build_course_pdfs(seed):
    for cid, meta in seed['courses'].items():
        c = COURSES[cid]
        sub = meta['level'].title() + ' course  |  Trainer: ' + meta['trainer']
        title = meta['title']

        # Study guide: every lecture slide as a short section, then the glossary.
        secs = [('About this guide', [meta['summary'],
                                      'These notes follow the video lecture for this course. Read them before or after '
                                      'watching, and use them to revise before the final quiz.']),
                ('What you will be able to do', ['- ' + o for o in meta['outcomes']])]
        for t, bullets, narration in c['slides']:
            secs.append((t, ['- ' + b for b in bullets] + [narration]))
        secs.append(('Glossary', ['%s: %s' % (term, d) for term, d in c['glossary']]))
        pdf('web/downloads/%s-study-guide.pdf' % cid, title + ' - Study guide', sub,
            [(_clean(h), [_clean(x) for x in body]) for h, body in secs])

        # Workbook: reflection, exercise and a seven-day action plan.
        ex_title, steps = c['exercise']
        secs = [('About this workbook', [meta['summary'],
                                         'Use it alongside the course player. Print it, or type your answers into a '
                                         'document. Writing things down makes them easier to remember and to act on.']),
                ('Reflection questions', ['%d. %s' % (i + 1, q) for i, q in enumerate(c['reflect'])]
                 + ['Write your answers below each question. There are no right answers.']),
                ('Exercise: ' + ex_title, ['%d. %s' % (i + 1, s) for i, s in enumerate(steps)]),
                ('Seven-day action plan', ['Choose one outcome from this course to practise.',
                                           'Day 1: decide the situation where you will use it.',
                                           'Day 2 to 6: use it once a day and write one line about what happened.',
                                           'Day 7: review. What worked, what will you change, who will you tell?',
                                           'Outcomes to choose from:'] + ['- ' + o for o in meta['outcomes']]),
                ('Confidence check', ['Rate your confidence with each outcome from 1 to 10 now, and again in two weeks.'])]
        pdf('web/downloads/%s-workbook.pdf' % cid, title + ' - Workbook', sub,
            [(_clean(h), [_clean(x) for x in body]) for h, body in secs])

        # Quick reference: the headline of each slide and the glossary.
        secs = [('The key ideas', ['- ' + t + ': ' + b[0] for t, b, _ in c['slides']]),
                ('Words to know', ['%s: %s' % (term, d) for term, d in c['glossary']]),
                ('Outcomes', ['- ' + o for o in meta['outcomes']])]
        pdf('web/downloads/%s-quick-reference.pdf' % cid, title + ' - Quick reference', sub,
            [(_clean(h), [_clean(x) for x in body]) for h, body in secs])
