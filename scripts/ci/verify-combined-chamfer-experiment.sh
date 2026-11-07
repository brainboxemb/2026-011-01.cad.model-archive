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
    cat "$log"
    rm -f "$log" "$out"
    echo "Combined hull differs from sectional reference (cs=$cs, ef=$ef)" >&2
    exit 1
  fi
  rm -f "$log" "$out"
done
echo "Combined straight-arm hull experiment: 4 symmetric-difference checks passed."
