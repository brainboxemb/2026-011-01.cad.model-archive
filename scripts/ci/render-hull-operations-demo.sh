#!/usr/bin/env bash
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

render 00_plain            00_plain
render 01_cs_inputs        01_cs_inputs
render 02_cs_result        02_cs_result
render 03_ef_inputs        03_ef_inputs
render 04_combined_result  04_combined_result
render 05_corner           05_corner
