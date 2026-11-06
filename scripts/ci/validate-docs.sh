#!/usr/bin/env bash
# Fail the build if generated documentation, STL files, or tutorial
# illustrations are absent from NopSCADlib outputs.
set -euo pipefail

spacer="examples/spacer/v0.1"
test -s "$spacer/stls/spacer.stl"
test -s "$spacer/stls/spacer.png"
test -s "$spacer/assemblies/main_assembled.png"
test -s "$spacer/bom/bom.json"
test -s "$spacer/readme.html"
grep -q 'Example spacer' "$spacer/readme.md"

bracket="models/corner_bracket/v0.1"
test -s "$bracket/stls/corner_bracket.stl"
test -s "$bracket/stls/access_plugs.stl"
test -s "$bracket/assemblies/main_assembled.png"
test -s "$bracket/bom/bom.json"
test -s "$bracket/readme.md"
test -s "$bracket/readme.html"
test -s "$bracket/printme.html"
grep -q 'Corner bracket' "$bracket/readme.md"

# Mounting alternatives must be generated and linked from the model page.
test -s "$bracket/mounting-options.md"
test -s "$bracket/mounting-options.html"
grep -Fq 'mounting-options.html' "$bracket/readme.md"
grep -Fq 'mounting-options.html' "$bracket/readme.html"
grep -Fq 'counter-bracket' "$bracket/mounting-options.html"
grep -Fq 'B0F412QQ32' "$bracket/mounting-options.html"
grep -Fq '6834946' "$bracket/mounting-options.html"
grep -Fq '12120010' "$bracket/mounting-options.html"
grep -Fq '<table>' "$bracket/mounting-options.html"

# The design guide must retain actual SCAD code, not just rendered images.
for source_module in \
  'module profile()' 'module side_chamfer_env()' \
  'module nut_top()' 'module ef_cuts()' \
  'module plug_local()' 'module plugs_in_place()' \
  'module sloped_hull()' 'module hull_of_circles()' \
  'module sharp_L()'; do
  grep -Fq "$source_module" "$bracket/readme.md"
  grep -Fq "$source_module" "$bracket/readme.html"
done
grep -Fq '<pre><code>' "$bracket/readme.html"
grep -Fq 'cos(a)' "$bracket/readme.md"

# Each teaching stage must have both a rendered image and a document link.
check_image() {
  local file="$1"
  test -s "$bracket/design/$file.png"
  grep -Fq "design/$file.png" "$bracket/readme.md"
  grep -Fq "design/$file.png" "$bracket/readme.html"
}

for stage in 01_profile 02_edge_chamfers 03_nut_pockets 04_print_relief 05_access_plugs 06_installed; do
  check_image "$stage"
done
for stage in 01_original_bar 02_wide_layer 03_two_layers 04_hull 05_result; do
  check_image "hull_$stage"
done
for stage in 01_four_circles 02_hull_of_circles 03_sharp_L 04_circle_guide 05_arc_points 06_rounded_L 07_hull_fills_corner; do
  check_image "rounding_$stage"
done

echo "Verified generated documentation and all design illustrations."
