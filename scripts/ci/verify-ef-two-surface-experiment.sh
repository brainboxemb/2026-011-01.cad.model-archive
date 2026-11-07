#!/usr/bin/env bash
# Quantify the dedicated elephant-foot two-surface hull experiment.
# This does NOT gate on a preselected "must fail" conclusion. It verifies
# that all experimental solids render and reports reference/candidate/XOR,
# overcut and undercut volumes so the geometry can be judged from evidence.
#
# Run in the container with cwd models/corner_bracket/v0.1.
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fixture="design/ef_hull_experiment.scad"

# A few representative positive cs/ef combinations. The visual guide uses
# the first/default case.
cases=(
  "2 0.6 2"
  "3 1.2 2"
  "2 0.3 2"
)

render_stl() {
  local step="$1" cs="$2" ef="$3" radius="$4" outfile="$5" log="$6"
  local exitcode=0
  rm -f "$outfile"
  openscad -o "$outfile" \
    -D "cs=$cs" -D "ef=$ef" -D "r_in=$radius" \
    -D "experiment_step=\"$step\"" \
    "$fixture" >"$log" 2>&1 || exitcode=$?

  if grep -q 'Current top level object is empty' "$log"; then
    # Empty XOR/overcut/undercut is a legitimate result.
    return 0
  fi
  if [[ "$exitcode" -ne 0 ]]; then
    echo "OpenSCAD failed ($step, cs=$cs, ef=$ef, r_in=$radius)" >&2
    cat "$log" >&2
    exit 1
  fi
}

for case in "${cases[@]}"; do
  read -r cs ef radius <<< "$case"

  declare -A step_for=(
    [reference]="08_reference_cutter"
    [candidate]="11_exact_two_surface_hull"
    [xor]="13_exact_candidate_xor"
    [overcut]="14_exact_candidate_overcut"
    [undercut]="15_exact_candidate_undercut"
    [missing_tip]="07_missing_tip_volume"
  )

  for name in reference candidate xor overcut undercut missing_tip; do
    render_stl "${step_for[$name]}" "$cs" "$ef" "$radius" \
      "$tmp/$name.stl" "$tmp/$name.log"
  done

  python3 - "$tmp" "$cs" "$ef" "$radius" <<'PY'
import re
import sys
from pathlib import Path

folder, cs, ef, radius = sys.argv[1:]

def stl_volume(path: Path) -> float:
    if not path.exists():
        return 0.0
    vertices = []
    with path.open(errors="replace") as file:
        for line in file:
            match = re.match(
                r"\s*vertex\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)",
                line,
            )
            if match:
                vertices.append(tuple(float(x) for x in match.groups()))
    if len(vertices) % 3:
        raise SystemExit(f"Invalid STL triangle data: {path.name}")
    total6 = 0.0
    for a, b, c in zip(vertices[::3], vertices[1::3], vertices[2::3]):
        n = (
            b[1]*c[2]-b[2]*c[1],
            b[2]*c[0]-b[0]*c[2],
            b[0]*c[1]-b[1]*c[0],
        )
        total6 += sum(a[i]*n[i] for i in range(3))
    return abs(total6) / 6.0

names = ["reference", "candidate", "xor", "overcut", "undercut", "missing_tip"]
v = {name: stl_volume(Path(folder, name + ".stl")) for name in names}

if v["reference"] <= 0:
    raise SystemExit("Reference cutter unexpectedly empty")
if v["candidate"] <= 0:
    raise SystemExit("Two-surface candidate unexpectedly empty")

# Symmetric difference should equal overcut + undercut apart from tiny
# tessellation/numerical differences.
split_error = abs(v["xor"] - (v["overcut"] + v["undercut"]))
if split_error > max(1e-4, v["xor"] * 0.01):
    raise SystemExit(
        f"XOR split inconsistent: xor={v['xor']:.6f}, "
        f"over+under={v['overcut'] + v['undercut']:.6f}"
    )

print(
    f"EF two-surface experiment cs={cs}, ef={ef}, r_in={radius}: "
    f"reference={v['reference']:.6f}, candidate={v['candidate']:.6f}, "
    f"xor={v['xor']:.6f}, overcut={v['overcut']:.6f}, "
    f"undercut={v['undercut']:.6f}, missing-tip={v['missing_tip']:.6f} mm^3"
)
PY

done

echo "Elephant-foot two-surface experiment rendered and quantified: ${#cases[@]} configurations."
