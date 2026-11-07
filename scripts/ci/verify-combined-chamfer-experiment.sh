#!/usr/bin/env bash
# Run inside the OpenSCAD container, from models/corner_bracket/v0.1.
set -euo pipefail
source_file="design/combined_chamfer_hull.scad"
for config in "2 0.6" "0 0.6" "2 0" "3 1.2"; do
  read -r cs ef <<< "$config"
  log="$(mktemp)"
  out="$(mktemp --suffix=.stl)"
  openscad -o "$out" -D 'view="xor"' \
    -D "upper_chamfer=$cs" -D "elephant_foot=$ef" "$source_file" >"$log" 2>&1
  if ! grep -q 'Current top level object is empty' "$log"; then
    # CGAL can leave a microscopic tetrahedron at a shared hull facet,
    # even when the exact mathematical solids are equivalent.
    # Accept no more than 0.001 cubic mm of residual mesh volume.
    python3 - "$out" "$cs" "$ef" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(errors="replace")
points = []
for line in text.splitlines():
    match = re.match(r"\s*vertex\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)", line)
    if match:
        points.append(tuple(map(float, match.groups())))
if len(points) % 3:
    raise SystemExit(f"Malformed STL residual: {path}")
volume6 = 0.0
for a, b, c in zip(points[::3], points[1::3], points[2::3]):
    cross = (b[1]*c[2] - b[2]*c[1],
             b[2]*c[0] - b[0]*c[2],
             b[0]*c[1] - b[1]*c[0])
    volume6 += a[0]*cross[0] + a[1]*cross[1] + a[2]*cross[2]
vol = abs(volume6)/6.0
print(f"cs={sys.argv[2]}, ef={sys.argv[3]}: XOR residual volume {vol:.9g} mm^3")
if vol > 0.001:
    raise SystemExit("Combined hull differs materially from sectional reference")
PY
  fi
  rm -f "$log" "$out"
done
echo "Combined straight-arm hull experiment: 4 symmetric-difference checks passed."
