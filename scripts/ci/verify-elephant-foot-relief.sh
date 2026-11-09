#!/usr/bin/env bash
# Verify that the readable fixed-rotation arm-tip correction matches the
# former multmatrix() placement while keeping a non-zero local correction.
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fixture="tests/elephant-foot-equivalence.scad"

# side_edge_chamfer, elephant_foot_relief, inside_corner_radius
cases=(
  "2 0.6 2"
  "2 0 2"
  "0 0.6 2"
  "2 0.6 0"
  "2 0.6 4"
  "3 1.2 2"
  "2 0.3 2"
)

for case in "${cases[@]}"; do
  read -r side_chamfer print_relief radius <<< "$case"

  for variant in current legacy xor tip_effect; do
    outfile="$tmp/$variant.stl"
    log="$tmp/$variant.log"
    rm -f "$outfile"

    exitcode=0
    openscad -o "$outfile" \
      -D "side_edge_chamfer=$side_chamfer" \
      -D "elephant_foot_relief=$print_relief" \
      -D "inside_corner_radius=$radius" \
      -D "test_view=\"$variant\"" \
      "$fixture" >"$log" 2>&1 || exitcode=$?

    if [[ "$variant" == xor || "$variant" == tip_effect ]] \
       && grep -q 'Current top level object is empty' "$log"; then
      : # Empty difference is valid.
    elif [[ "$exitcode" -ne 0 ]]; then
      echo "OpenSCAD failed ($variant, side=$side_chamfer, relief=$print_relief, radius=$radius)" >&2
      cat "$log" >&2
      exit 1
    fi
  done

  python3 - "$tmp" "$side_chamfer" "$print_relief" "$radius" <<'PY'
import re
import sys
from pathlib import Path

folder, side_chamfer, print_relief, radius = sys.argv[1:]
variants = ("current", "legacy", "xor", "tip_effect")
volume = {}
bounds = {}

for variant in variants:
    path = Path(folder, variant + ".stl")
    vertices = []
    if path.exists():
        with path.open(errors="replace") as file:
            for line in file:
                m = re.match(r"\s*vertex\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)", line)
                if m:
                    vertices.append(tuple(float(x) for x in m.groups()))

    if len(vertices) % 3:
        raise SystemExit(f"Invalid STL triangle data: {variant}")

    total6 = 0.0
    for a, b, c in zip(vertices[::3], vertices[1::3], vertices[2::3]):
        n = (
            b[1] * c[2] - b[2] * c[1],
            b[2] * c[0] - b[0] * c[2],
            b[0] * c[1] - b[1] * c[0],
        )
        total6 += sum(a[i] * n[i] for i in range(3))

    volume[variant] = abs(total6) / 6
    bounds[variant] = (
        [(min(v[i] for v in vertices), max(v[i] for v in vertices)) for i in range(3)]
        if vertices else None
    )

if volume["current"] < 100:
    raise SystemExit("Invalid current relief body volume")

relative = volume["xor"] / volume["current"]
print(
    f"side={side_chamfer}, relief={print_relief}, radius={radius}: "
    f"current={volume['current']:.4f}, legacy={volume['legacy']:.4f}, "
    f"XOR={volume['xor']:.6f} mm^3 ({relative:.6%}), "
    f"tip-effect={volume['tip_effect']:.6f} mm^3"
)

# Fixed rotations should be effectively identical to the legacy matrix.
if relative > 0.00001:
    raise SystemExit("Fixed rotations differ from legacy multmatrix by >0.001%")

if float(side_chamfer) > 0 and float(print_relief) > 0:
    if volume["tip_effect"] < 0.01:
        raise SystemExit("Arm-tip correction unexpectedly has no effect")
else:
    if volume["tip_effect"] > 0.001:
        raise SystemExit("Arm-tip correction should be disabled")

if any(
    abs(a - b) > 0.002
    for current_axis, legacy_axis in zip(bounds["current"], bounds["legacy"])
    for a, b in zip(current_axis, legacy_axis)
):
    raise SystemExit("Bounding box changed")
PY
done

echo "Arm-tip relief regression passed: ${#cases[@]} configurations."
