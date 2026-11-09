#!/usr/bin/env bash
# Regression for the full printable bracket's elephant-foot relief.
# Production uses explicit cut geometry; the former hull implementation is
# retained in the fixture only as an independent near-equivalence reference.
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
  "2 0.6 1"
  "2 0.6 4"
  "2 0.6 8"
  "3 1.2 2"
  "2 0.3 2"
)

for case in "${cases[@]}"; do
  read -r side_chamfer print_relief radius <<< "$case"

  for variant in direct former_hull xor tip_xor tip_xor_without_miters; do
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

    if [[ "$variant" == xor || "$variant" == tip_xor || "$variant" == tip_xor_without_miters ]] \
       && grep -q 'Current top level object is empty' "$log"; then
      : # Correct zero difference.
    elif [[ "$exitcode" -ne 0 ]]; then
      echo "OpenSCAD failed ($variant, side=$side_chamfer, relief=$print_relief, radius=$radius)" >&2
      cat "$log" >&2
      exit 1
    fi

    if [[ "$variant" == direct || "$variant" == former_hull ]] \
       && grep -q 'not be a valid 2-manifold' "$log"; then
      echo "Model is not manifold ($variant, side=$side_chamfer, relief=$print_relief, radius=$radius)" >&2
      cat "$log" >&2
      exit 1
    fi
  done

  python3 - "$tmp" "$side_chamfer" "$print_relief" "$radius" <<'PY'
import re
import sys
from pathlib import Path

folder, side_chamfer, print_relief, radius = sys.argv[1:]
variants = (
    "direct",
    "former_hull",
    "xor",
    "tip_xor",
    "tip_xor_without_miters",
)
volume = {}
bounds = {}

for variant in variants:
    path = Path(folder, variant + ".stl")
    vertices = []

    if path.exists():
        with path.open(errors="replace") as file:
            for line in file:
                match = re.match(
                    r"\s*vertex\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)",
                    line,
                )
                if match:
                    vertices.append(tuple(float(x) for x in match.groups()))

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
        [
            (min(v[i] for v in vertices), max(v[i] for v in vertices))
            for i in range(3)
        ]
        if vertices
        else None
    )

if volume["direct"] < 100:
    raise SystemExit("Invalid direct-cutter model volume")

relative = volume["xor"] / volume["direct"]
print(
    f"side={side_chamfer}, relief={print_relief}, radius={radius}: "
    f"direct={volume['direct']:.4f}, former-hull={volume['former_hull']:.4f}, "
    f"XOR={volume['xor']:.4f} mm^3 ({relative:.4%})"
)

# This is the same near-equivalence limit used while the hull refactor was
# production code. The direction is now reversed: the direct cutter is the
# production reference and the former hull is historical.
if relative > 0.001:
    raise SystemExit("Former hull and direct relief differ by >0.1%")

if float(side_chamfer) > 0 and float(print_relief) > 0:
    without_miters = volume["tip_xor_without_miters"]
    with_miters = volume["tip_xor"]
    print(
        f"  arm-tip XOR: former hull without miters={without_miters:.5f}, "
        f"with miters={with_miters:.5f} mm^3"
    )
    if without_miters < 0.05:
        raise SystemExit("Arm-tip comparison region unexpectedly empty")
    if with_miters >= without_miters * 0.1:
        raise SystemExit(
            "Former hull miter correction must still remove at least 90% "
            "of its local difference from the direct cutter"
        )

if print_relief == "0" and volume["xor"] > 0.001:
    raise SystemExit("Disabling print relief must make both implementations equal")

if any(
    abs(a - b) > 0.002
    for direct_axis, hull_axis in zip(bounds["direct"], bounds["former_hull"])
    for a, b in zip(direct_axis, hull_axis)
):
    raise SystemExit("Bounding box changed")
PY
done

echo "Elephant-foot relief regression passed: ${#cases[@]} configurations."
