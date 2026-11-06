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

# The main manual should remain concise and link to two focused guides.
for page in mounting-options hull-guide; do
  test -s "$bracket/$page.md"
  test -s "$bracket/$page.html"
  grep -Fq "$page.html" "$bracket/readme.md"
  grep -Fq "$page.html" "$bracket/readme.html"
done

# Mounting diagrams are editable SVG files. The generated HTML must link to them.
for svg in mounting-a-inside-out mounting-b-outside-in mounting-c-counter-outside-in mounting-d-counter-inside-out m4-nuts-hex-square; do
  test -s "$bracket/figures/$svg.svg"
  grep -Fq "figures/$svg.svg" "$bracket/mounting-options.md"
  grep -Fq "figures/$svg.svg" "$bracket/mounting-options.html"
done
grep -Fq 'counter-bracket' "$bracket/mounting-options.html"
grep -Fq 'B0F412QQ32' "$bracket/mounting-options.html"
grep -Fq '6834946' "$bracket/mounting-options.html"
grep -Fq '12120010' "$bracket/mounting-options.html"
grep -Fq '<table>' "$bracket/mounting-options.html"

# Elephant-foot compensation has its own illustrated explanation in the manual.
for svg in elephant-foot-section elephant-foot-edges; do
  test -s "$bracket/figures/$svg.svg"
  grep -Fq "figures/$svg.svg" "$bracket/readme.md"
  grep -Fq "figures/$svg.svg" "$bracket/readme.html"
done
grep -Fq 'Y = +W/2' "$bracket/readme.md"

# Main design documentation must retain real code, without the long hull tutorial.
for source_module in \
  'module profile()' 'module side_chamfer_env()' \
  'module nut_top()' 'module ef_cuts()' \
  'module plug_local()' 'module plugs_in_place()'; do
  grep -Fq "$source_module" "$bracket/readme.md"
  grep -Fq "$source_module" "$bracket/readme.html"
done
grep -Fq '<pre><code>' "$bracket/readme.html"
if grep -Fq '#### A. Start with a plain bar' "$bracket/readme.md"; then
  echo "Extended hull tutorial leaked back into the main design manual" >&2
  exit 1
fi

# The separate hull guide owns both original step-by-step demonstrations.
for source_module in 'module sloped_hull()' 'module hull_of_circles()' 'module sharp_L()'; do
  grep -Fq "$source_module" "$bracket/hull-guide.md"
  grep -Fq "$source_module" "$bracket/hull-guide.html"
done
grep -Fq 'cos(a)' "$bracket/hull-guide.md"

# Each image is used by exactly the intended guide, with working relative URLs.
check_image() {
  local file="$1" page="$2"
  test -s "$bracket/design/$file.png"
  grep -Fq "design/$file.png" "$bracket/$page.md"
  grep -Fq "design/$file.png" "$bracket/$page.html"
}

for stage in 01_profile 02_edge_chamfers 03_nut_pockets 04_print_relief 05_access_plugs 06_installed; do
  check_image "$stage" readme
done
for stage in 01_original_bar 02_wide_layer 03_two_layers 04_hull 05_result; do
  check_image "hull_$stage" hull-guide
done
for stage in 01_four_circles 02_hull_of_circles 03_sharp_L 04_circle_guide 05_arc_points 06_rounded_L 07_hull_fills_corner; do
  check_image "rounding_$stage" hull-guide
done

echo "Verified generated documentation and all design illustrations."
