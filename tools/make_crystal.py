"""Writes assets/models/crystal.glb: a faceted, flat-shaded alchemy crystal.

Stdlib only. Run with: python -I tools/make_crystal.py
Shape: octagonal bipyramid with a slightly offset, rotated waist ring.
"""
import json
import math
import os
import struct

SIDES = 8
TOP = (0.12, 1.55, 0.0)
BOTTOM = (-0.08, -1.15, 0.0)
# (y, radius, twist offset in radians, (x, z) shift) rings, bottom to top
RINGS = [
    (-0.55, 0.62, 0.0, (-0.04, 0.0)),
    (0.15, 0.78, math.pi / SIDES, (0.03, 0.02)),
    (0.75, 0.50, 0.0, (0.06, 0.0)),
]


def ring_pts(y, r, twist, shift):
    pts = []
    for i in range(SIDES):
        a = twist + 2 * math.pi * i / SIDES
        pts.append((shift[0] + r * math.cos(a), y, shift[1] + r * math.sin(a)))
    return pts


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def cross(a, b):
    return (
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    )


def norm(v):
    length = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / length for c in v)


tris = []
rings = [ring_pts(*r) for r in RINGS]
for i in range(SIDES):
    j = (i + 1) % SIDES
    tris.append((BOTTOM, rings[0][j], rings[0][i]))
    for k in range(len(rings) - 1):
        a, b = rings[k], rings[k + 1]
        tris.append((a[i], a[j], b[j]))
        tris.append((a[i], b[j], b[i]))
    tris.append((TOP, rings[-1][i], rings[-1][j]))

positions, normals = [], []
for t in tris:
    n = norm(cross(sub(t[1], t[0]), sub(t[2], t[0])))
    # Make sure the face normal points away from the crystal core.
    c = tuple(sum(p[x] for p in t) / 3 for x in range(3))
    if n[0] * c[0] + n[1] * (c[1] - 0.2) + n[2] * c[2] < 0:
        t = (t[0], t[2], t[1])
        n = tuple(-x for x in n)
    for p in t:
        positions.append(p)
        normals.append(n)

n_vert = len(positions)
pos_bytes = b"".join(struct.pack("<3f", *p) for p in positions)
nor_bytes = b"".join(struct.pack("<3f", *n) for n in normals)
idx_bytes = b"".join(struct.pack("<H", i) for i in range(n_vert))
idx_len = len(idx_bytes)
while len(idx_bytes) % 4:
    idx_bytes += b"\x00"
bin_data = pos_bytes + nor_bytes + idx_bytes

mins = [min(p[i] for p in positions) for i in range(3)]
maxs = [max(p[i] for p in positions) for i in range(3)]
gltf = {
    "asset": {"version": "2.0", "generator": "tools/make_crystal.py"},
    "scene": 0,
    "scenes": [{"nodes": [0]}],
    "nodes": [{"mesh": 0, "name": "Crystal"}],
    "meshes": [
        {
            "primitives": [
                {
                    "attributes": {"POSITION": 0, "NORMAL": 1},
                    "indices": 2,
                    "material": 0,
                    "mode": 4,
                }
            ]
        }
    ],
    "materials": [
        {
            "name": "SapphireGlass",
            "doubleSided": True,
            "alphaMode": "BLEND",
            "pbrMetallicRoughness": {
                "baseColorFactor": [0.30, 0.25, 0.80, 0.9],
                "metallicFactor": 0.1,
                "roughnessFactor": 0.25,
            },
        }
    ],
    "buffers": [{"byteLength": len(bin_data)}],
    "bufferViews": [
        {"buffer": 0, "byteOffset": 0, "byteLength": len(pos_bytes), "target": 34962},
        {
            "buffer": 0,
            "byteOffset": len(pos_bytes),
            "byteLength": len(nor_bytes),
            "target": 34962,
        },
        {
            "buffer": 0,
            "byteOffset": len(pos_bytes) + len(nor_bytes),
            "byteLength": idx_len,
            "target": 34963,
        },
    ],
    "accessors": [
        {
            "bufferView": 0,
            "componentType": 5126,
            "count": n_vert,
            "type": "VEC3",
            "min": mins,
            "max": maxs,
        },
        {"bufferView": 1, "componentType": 5126, "count": n_vert, "type": "VEC3"},
        {"bufferView": 2, "componentType": 5123, "count": n_vert, "type": "SCALAR"},
    ],
}
json_bytes = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
while len(json_bytes) % 4:
    json_bytes += b" "

total = 12 + 8 + len(json_bytes) + 8 + len(bin_data)
glb = (
    struct.pack("<4sII", b"glTF", 2, total)
    + struct.pack("<I4s", len(json_bytes), b"JSON")
    + json_bytes
    + struct.pack("<I4s", len(bin_data), b"BIN\x00")
    + bin_data
)

out = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "assets", "models", "crystal.glb"
)
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "wb") as f:
    f.write(glb)

# Validation: header, alignment, chunk lengths.
data = open(out, "rb").read()
magic, ver, length = struct.unpack_from("<4sII", data, 0)
assert magic == b"glTF" and ver == 2 and length == len(data), "bad header"
off, chunks = 12, []
while off < length:
    clen, ctype = struct.unpack_from("<I4s", data, off)
    assert clen % 4 == 0, "chunk not 4-byte aligned"
    chunks.append(ctype)
    off += 8 + clen
assert off == length and chunks == [b"JSON", b"BIN\x00"], "bad chunks"
assert len(data) < 50 * 1024, "too large"
print(f"OK {os.path.normpath(out)}: {len(data)} bytes, {n_vert} vertices, {len(tris)} faces")
