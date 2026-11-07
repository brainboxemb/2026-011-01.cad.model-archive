#!/usr/bin/env bash
# Regression for the full printable bracket, including pockets and inside arc.
# Uses no Python packages; parses ASCII STLs exported by OpenSCAD.
# Run in the container with cwd models/corner_bracket/v0.1.
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fixture="tests/elephant-foot-equivalence.scad"

# cs, ef, r_in: default, disabled controls and corner radii.
cases=(
  "2 0.6 2"
  "2 0 2"
  "0 0.6 2"
  "2 0.6 0"
  "2 0.6 1"
  "2 0.6 4"
  "2 0.6 8"
  "3 1.2 2"
  "2 0.3 2"
)
for case in "${cases[@]}"; do
  read -r cs ef radius <<< "$case"
  for variant in old new xor; do
    outfile="$tmp/$variant.stl"
    log="$tmp/$variant.log"
    rm -f "$outfile"
    exitcode=0
    openscad -o "$outfile" -D "cs=$cs" -D "ef=$ef" \
      -D "r_in=$radius" -D "test_view=\"$variant\"" \
      "$fixture" >"$log" 2>&1 || exitcode=$?
    # OpenSCAD may exit non-zero when the XOR is completely empty.
    if [[ "$variant" == xor ]] && grep -q 'Current top level object is empty' "$log"; then
      : # correct zero difference
    elif [[ "$exitcode" -ne 0 ]]; then
      echo "OpenSCAD failed ($variant, cs=$cs, ef=$ef, r_in=$radius)" >&2
      cat "$log" >&2
      exit 1
    fi
    if [[ "$variant" != xor ]] && grep -q 'not be a valid 2-manifold' "$log"; then
      echo "Model is not manifold ($variant, cs=$cs, ef=$ef, r_in=$radius)" >&2
      cat "$log" >&2
      exit 1
    fi
  done

  python3 - "$tmp" "$cs" "$ef" "$radius" <<'PY'
import re
import sys
from pathlib import Path

folder, cs, ef, radius = sys.argv[1:]
volume = {}
bounds = {}
for variant in ("old", "new", "xor"):
    path = Path(folder, variant + ".stl")
    vertices = []
    if path.exists():
        with path.open(errors="replace") as file:
            for line in file:
                match = re.match(r"\s*vertex\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)", line)
                if match:
                    vertices.append(tuple(float(x) for x in match.groups()))
    if len(vertices) % 3:
        raise SystemExit(f"Invalid STL triangle data: {variant}")
    total6 = 0.0
    for a, b, c in zip(vertices[::3], vertices[1::3], vertices[2::3]):
        n = (b[1]*c[2]-b[2]*c[1],
             b[2]*c[0]-b[0]*c[2],
             b[0]*c[1]-b[1]*c[0])
        total6 += sum(a[i]*n[i] for i in range(3))
    volume[variant] = abs(total6)/6
    bounds[variant] = [(min(v[i] for v in vertices), max(v[i] for v in vertices))
                       for i in range(3)] if vertices else None

if volume["old"] < 100:
    raise SystemExit("Invalid reference model volume")
relative = volume["xor"] / volume["old"]
print(f"cs={cs}, ef={ef}, r_in={radius}: "
      f"legacy={volume['old']:.4f}, new={volume['new']:.4f}, "
      f"XOR={volume['xor']:.4f} mm^3 ({relative:.4%})")
if relative > 0.001:
    raise SystemExit("Hull relief changes >0.1% of the legacy solid")
if ef == "0" and volume["xor"] > 0.001:
    raise SystemExit("Disabling elephant-foot relief must restore exact original")
if any(abs(a-b) > 0.002
       for ax0, ax1 in zip(bounds["old"],bounds["new"])
       for a,b in zip(ax0,ax1)):
    raise SystemExit("Bounding box changed")
PY
done
echo "Full-bracket hull relief regression passed: ${#cases[@]} configurations."
