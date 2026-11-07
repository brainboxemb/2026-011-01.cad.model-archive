#!/usr/bin/env bash
# Render the four beam states with one fixed camera/orientation.
set -euo pipefail

cd "$(dirname "$0")/../../examples/hull_operations/v0.1"
mkdir -p renders

render() {
  local scene="$1"
  local output="$2"
  xvfb-run -a openscad \
    --imgsize=800,500 \
    --viewall --autocenter \
    -D "scene=$scene" \
    -o "renders/$output.png" \
    scad/hull_operations.scad
  test -s "renders/$output.png"
}

render 0 00_plain_beam
render 1 01_side_chamfer
render 2 02_elephant_foot
render 3 03_combined
