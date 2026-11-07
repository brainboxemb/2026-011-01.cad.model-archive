#!/usr/bin/env bash
# Render the beam hull experiment with one fixed orientation.
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

render 00_plain      00_plain
render 01_cs_inputs  01_cs_inputs
render 02_cs_result  02_cs_result
render 03_ef_inputs  03_ef_inputs
render 04_ef_result  04_ef_result
render 05_combined   05_combined
render 06_corner       06_corner
render 07_miter_inputs 07_miter_inputs
render 08_fixed        08_fixed
