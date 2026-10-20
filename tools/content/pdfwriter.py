"""Minimal text-only PDF writer used for the downloadable study material."""
import textwrap

def esc(t):
    b = chr(92)
    return t.replace(b, b + b).replace('(', b + '(').replace(')', b + ')')

def pdf(path, title, subtitle, sections):
    pages = []
    lines = []
    for heading, body in sections:
        lines.append(('h', heading))
        for para in body:
            for l in textwrap.wrap(para, 86): lines.append(('p', l))
            lines.append(('p', ''))
    per = 38
    chunks = [lines[i:i + per] for i in range(0, len(lines), per)] or [[]]
    for n, chunk in enumerate(chunks):
        ops = ['0.106 0.165 0.471 rg 0 792 612 -86 re f',
               '0.416 0.239 0.722 rg 0 706 612 -6 re f']  # deep blue band with a purple edge
        ops.append('BT /F2 22 Tf 1 1 1 rg 56 748 Td (%s) Tj ET' % esc(title))
        ops.append('BT /F1 11 Tf 1 1 1 rg 56 726 Td (%s) Tj ET' % esc(subtitle))
        y = 670
        for kind, text in chunk:
            if kind == 'h':
                y -= 6
                ops.append('BT /F2 13 Tf 0.094 0.094 0.106 rg 56 %d Td (%s) Tj ET' % (y, esc(text)))
                y -= 20
            else:
                ops.append('BT /F1 10.5 Tf 0.25 0.25 0.27 rg 56 %d Td (%s) Tj ET' % (y, esc(text)))
                y -= 15
        ops.append('0.894 0.894 0.906 RG 56 60 m 556 60 l S')
        ops.append('BT /F1 9 Tf 0.44 0.44 0.48 rg 56 44 Td (MT Alchemy  |  We shift mindsets, behaviours and team culture.   Page %d of %d) Tj ET' % (n + 1, len(chunks)))
        pages.append('\n'.join(ops))
    objs = ['<< /Type /Catalog /Pages 2 0 R >>', None,
            '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
            '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>']
    kids = []
    for content in pages:
        objs.append('<< /Length %d >>\nstream\n%s\nendstream' % (len(content.encode('latin-1')), content))
        objs.append('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents %d 0 R >>' % (len(objs)))
        kids.append('%d 0 R' % len(objs))
    objs[1] = '<< /Type /Pages /Kids [%s] /Count %d >>' % (' '.join(kids), len(kids))
    out = b'%PDF-1.4\n'; offs = []
    for i, o in enumerate(objs):
        offs.append(len(out)); out += ('%d 0 obj\n%s\nendobj\n' % (i + 1, o)).encode('latin-1')
    x = len(out)
    out += ('xref\n0 %d\n0000000000 65535 f \n' % (len(objs) + 1)).encode()
    out += ''.join('%010d 00000 n \n' % o for o in offs).encode()
    out += ('trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n' % (len(objs) + 1, x)).encode()
    open(path, 'wb').write(out)

