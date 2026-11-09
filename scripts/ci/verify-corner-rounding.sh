#!/usr/bin/env bash
# Run within the central OpenSCAD toolchain, cwd=corner_bracket/v0.1.
# OpenSCAD returns 1 and reports an empty top-level object when the
# symmetric difference of two matching solids has no geometry.
set -euo pipefail

test -s scad/corner_bracket.scad
test -s tests/inside-corner-equivalence.scad
temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT

# Check the zero-radius edge case, default R=2, larger fillets, and
# print-relief combinations. These do not change the bracket design.
for override in 'inside_corner_radius=0' 'inside_corner_radius=1' 'inside_corner_radius=2' 'inside_corner_radius=4' 'inside_corner_radius=8' 'elephant_foot_relief=0' 'inside_corner_radius=4;elephant_foot_relief=0' 'inside_corner_radius=8;elephant_foot_relief=0'; do
  name="${override//[^a-zA-Z0-9]/_}"
  options=()
  IFS=';' read -r -a settings <<< "$override"
  for setting in "${settings[@]}"; do
    options+=(-D "$setting")
  done

  # A non-empty geometry must be treated as a regression. Empty geometry
  # returns nonzero in OpenSCAD; only the specific empty-object output is OK.
  if openscad "${options[@]}" -o "$temp/$name.stl" \
    tests/inside-corner-equivalence.scad > "$temp/$name.stdout" 2> "$temp/$name.stderr"; then
    echo "Geometry mismatch: symmetric difference is not empty ($override)" >&2
    exit 1
  fi
  if ! grep -Fq 'Current top level object is empty.' "$temp/$name.stderr"; then
    cat "$temp/$name.stderr" >&2
    echo "OpenSCAD error while comparing geometry ($override)" >&2
    exit 1
  fi
  test ! -s "$temp/$name.stl" || {
    echo "Unexpected STL emitted from geometry difference ($override)" >&2
    exit 1
  }
  echo "Inside radius equivalence: $override OK"
done
