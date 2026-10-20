"""Joins slide images and narration into assets/videos/lectures/<id>-lecture.mp4.
Uses the ffmpeg that ships with Remotion. Run from the repo root:
    python tools/content/assemble_lectures.py [course-id]
"""
import json, os, subprocess, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
BIN = os.path.join(ROOT, 'video', 'node_modules', '@remotion', 'compositor-win32-x64-msvc')
FFMPEG, FFPROBE = os.path.join(BIN, 'ffmpeg.exe'), os.path.join(BIN, 'ffprobe.exe')
SRC = os.path.join(ROOT, 'build', 'lectures')
OUT = os.path.join(ROOT, 'assets', 'videos', 'lectures')
os.makedirs(OUT, exist_ok=True)
GAP = 0.8  # seconds of quiet after each slide


def run(args):
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(r.stderr[-1500:])
    return r.stdout


def duration(path):
    return float(run([FFPROBE, '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', path]).strip())


def build(cid):
    d = os.path.join(SRC, cid)
    manifest = json.load(open(os.path.join(d, 'manifest.json'), encoding='utf-8'))
    parts, total = [], 0.0
    for i in range(len(manifest['segments'])):
        wav = os.path.join(d, 'seg%02d.wav' % i)
        png = os.path.join(d, 'slide%02d.png' % i)
        part = os.path.join(d, 'part%02d.mp4' % i)
        length = duration(wav) + GAP
        total += length
        run([FFMPEG, '-y', '-loop', '1', '-framerate', '5', '-i', png, '-i', wav,
             '-af', 'apad=pad_dur=%s' % GAP, '-t', '%.2f' % length,
             '-c:v', 'libx264', '-tune', 'stillimage', '-crf', '33', '-pix_fmt', 'yuv420p',
             '-vf', 'scale=1280:720', '-c:a', 'aac', '-b:a', '64k', '-ar', '44100', '-ac', '1', part])
        parts.append(part)
    listing = os.path.join(d, 'parts.txt')
    open(listing, 'w').write(''.join("file '%s'\n" % p.replace('\\', '/') for p in parts))
    out = os.path.join(OUT, cid + '-lecture.mp4')
    run([FFMPEG, '-y', '-f', 'concat', '-safe', '0', '-i', listing, '-c', 'copy', '-movflags', '+faststart', out])
    mins = duration(out) / 60
    print('%s: %.1f min, %.1f MB' % (cid, mins, os.path.getsize(out) / 1e6))
    return mins


if __name__ == '__main__':
    only = sys.argv[1] if len(sys.argv) > 1 else None
    short = []
    for cid in sorted(os.listdir(SRC)):
        if not os.path.isdir(os.path.join(SRC, cid)) or (only and cid != only):
            continue
        if build(cid) < 5:
            short.append(cid)
    if short:
        raise SystemExit('Shorter than 5 minutes: ' + ', '.join(short))
