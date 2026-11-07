#!/usr/bin/env bash
# Render the beam analogue and focused cs/ef junction with fixed orientation.
set -euo pipefail

cd "$(dirname "$0")/../../examples/hull_operations/v0.1"
mkdir -p renders

render() {
  local scene="$1"
  local output="$2"
  xvfb-run -a openscad \
    --imgsize=800,500 \
    --viewall --autocenter \
    -D "scene=\"$scene\"" \
    -o "renders/$output.png" \
    scad/hull_operations.scad
  test -s "renders/$output.png"
}

render 00_plain   00_plain_beam
render 01_normal_chamfers 01_normal_chamfers
render 02_problem 02_junction_problem
render 03_miter   03_miter_cutter
render 04_fixed   04_junction_fixed
render 05_final   05_final_beam
