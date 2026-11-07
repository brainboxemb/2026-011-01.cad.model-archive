#!/usr/bin/env bash
# Render the beam hull explanation with one fixed orientation.
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

render 00_plain         00_plain_beam
render 01_cs_inputs     01_cs_inputs
render 02_cs_result     02_cs_result
render 03_ef_inputs     03_ef_inputs
render 04_ef_result     04_ef_result
render 05_problem       05_junction_problem
render 06_miter_inputs  06_miter_inputs
render 07_fixed         07_junction_fixed
