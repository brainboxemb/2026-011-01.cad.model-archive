#!/usr/bin/env bash
# Fail the build if generated documentation, STL files, or tutorial
# illustrations are absent from NopSCADlib outputs.
set -euo pipefail
trap 'echo "Validation failed on line $LINENO: $BASH_COMMAND" >&2' ERR

require_text() {
  local pattern="$1" file="$2"
  if ! grep -Fq "$pattern" "$file"; then
    echo "Missing required text in $file: $pattern" >&2
    exit 1
  fi
}

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

# The source root holds exactly one model and one inspection helper.
test -s "$bracket/scad/corner_bracket.scad"
test -s "$bracket/scad/inspection.scad"
test ! -e "$bracket/scad/documentation.scad"
test "$(find "$bracket/scad" -maxdepth 1 -type f -name '*.scad' | wc -l)" -eq 2
for source in design hull_explained rounding_explained inside_corner_methods chamfer_explained combined_chamfer_hull; do
  test -s "$bracket/design/$source.scad"
done
test -s "$bracket/docs/documentation.scad"
test -s "$bracket/tests/inside-corner-equivalence.scad"
test -s "$bracket/tests/elephant-foot-equivalence.scad"
grep -Fq 'module inside_corner_2d(r)' "$bracket/scad/corner_bracket.scad"
grep -Fq 'module sharp_profile()' "$bracket/scad/corner_bracket.scad"
grep -Fq 'module inside_relief_envelope()' "$bracket/scad/corner_bracket.scad"
grep -Fq 'module relief_corner_miters()' "$bracket/scad/corner_bracket.scad"
if grep -Fq 'module ef_cuts()' "$bracket/scad/corner_bracket.scad"; then
  echo "Obsolete per-edge elephant-foot cutters still in production model" >&2
  exit 1
fi
grep -Fq 'module inside_corner_2d(r)' "$bracket/readme.md"
grep -Fq 'module sharp_profile()' "$bracket/readme.md"
if grep -Fq 'corner_arc = (r_in > 0)' "$bracket/scad/corner_bracket.scad"; then
  echo "Old sampled-point fillet returned to active model" >&2
  exit 1
fi

# The main manual should remain concise and link to two focused guides.
for page in mounting-options hull-guide polygon-guide chamfer-guide; do
  test -s "$bracket/docs/$page.md"
  test -s "$bracket/docs/$page.html"
  grep -Fq "docs/$page.html" "$bracket/readme.md"
  grep -Fq "docs/$page.html" "$bracket/readme.html"
done

# Mounting diagrams are editable SVG files. The generated HTML must link to them.
for svg in mounting-corner-overview mounting-a-inside-out mounting-b-outside-in mounting-c-counter-outside-in mounting-d-counter-inside-out mounting-e-pronged-t-nut m4-nuts-hex-square; do
  test -s "$bracket/figures/$svg.svg"
  grep -Fq "../figures/$svg.svg" "$bracket/docs/mounting-options.md"
  grep -Fq "../figures/$svg.svg" "$bracket/docs/mounting-options.html"
done
grep -Fq 'counter-bracket' "$bracket/docs/mounting-options.html"
grep -Fq 'B0F412QQ32' "$bracket/docs/mounting-options.html"
grep -Fq '6834946' "$bracket/docs/mounting-options.html"
grep -Fq '12120010' "$bracket/docs/mounting-options.html"
grep -Fq '12120360' "$bracket/docs/mounting-options.html"
grep -Fq 'Prongs point INTO plywood' "$bracket/figures/mounting-e-pronged-t-nut.svg"
grep -Fq '<table>' "$bracket/docs/mounting-options.html"
# Explicit product photo URLs supplied for these three candidate components.
for photo in '71+MwJjWJ+L._SL1500_.jpg' 'as.46905981.jpg' 'as.89415265.jpg' 'as.89415179.jpg'; do
  grep -Fq "$photo" "$bracket/docs/mounting-options.md"
  grep -Fq "$photo" "$bracket/docs/mounting-options.html"
done
grep -Fq '../figures/m4-bolt-head-types.svg' "$bracket/docs/mounting-options.html"
test -s "$bracket/figures/m4-bolt-head-types.svg"
for section in a-inside-out b-outside-in c-counter-outside-in d-counter-inside-out e-pronged-t-nut; do
  file="$bracket/figures/mounting-$section.svg"
  grep -Fq 'OUTSIDE' "$file"
  grep -Fq 'INSIDE' "$file"
  grep -Fq '520' "$file"
done

# Verify SVG files parse as vector drawings, not only that paths exist.
python3 - <<'PY'
from pathlib import Path
from xml.etree import ElementTree
figures = sorted(Path("models/corner_bracket/v0.1/figures").glob("*.svg"))
assert len(figures) >= 7, "Expected mounting and elephant-foot diagrams"
for figure in figures:
    root = ElementTree.parse(figure).getroot()
    assert root.tag == "{http://www.w3.org/2000/svg}svg", figure
    assert root.attrib.get("viewBox"), f"Missing viewBox: {figure}"
print(f"Validated {len(figures)} editable SVG illustrations")
PY

# Elephant-foot compensation has its own illustrated explanation in the manual.
for svg in elephant-foot-section elephant-foot-edges; do
  test -s "$bracket/figures/$svg.svg"
  grep -Fq "figures/$svg.svg" "$bracket/readme.md"
  grep -Fq "figures/$svg.svg" "$bracket/readme.html"
done
for svg in elephant-foot-hull-explained elephant-foot-junction; do
  test -s "$bracket/figures/$svg.svg"
  grep -Fq "../figures/$svg.svg" "$bracket/docs/chamfer-guide.md"
  grep -Fq "../figures/$svg.svg" "$bracket/docs/chamfer-guide.html"
done
if grep -Fq 'chamfer_10_corner_junction.png' "$bracket/docs/chamfer-guide.md"; then
  echo "Unreadable corner fragment illustration reintroduced" >&2
  exit 1
fi
# The main walkthrough summarizes the two main EF hulls and points to the
# dedicated Chamfer Guide for the detailed junction geometry.
require_text 'one per print side' "$bracket/readme.md"
require_text 'inside_relief_envelope()' "$bracket/readme.md"
require_text '### 2. Outer side-edge chamfers' "$bracket/readme.md"
require_text '## Printing and assembly' "$bracket/readme.md"
require_text '## Further reading' "$bracket/readme.md"
# The hull primer is linked at Step 2 and in Further reading.
require_text 'New to `hull()`?' "$bracket/readme.md"
test "$(grep -Fc 'hull-guide.html' "$bracket/readme.md")" -ge 2
if grep -Fq 'Why is there no `hull()` for the inside corner?' "$bracket/readme.md"; then
  echo "Redundant hull aside reintroduced into main design manual" >&2
  exit 1
fi

# Main design documentation must retain real code, without the long hull tutorial.
for source_module in \
  'module profile()' 'module side_chamfer_env()' \
  'module nut_top()' 'module chamfered_body()' \
  'module plug_local()' 'module plugs_in_place()'; do
  grep -Fq "$source_module" "$bracket/readme.md"
  grep -Fq "$source_module" "$bracket/readme.html"
done
grep -Fq '<pre><code>' "$bracket/readme.html"
if grep -Fq '#### A. Start with a plain bar' "$bracket/readme.md"; then
  echo "Extended hull tutorial leaked back into the main design manual" >&2
  exit 1
fi

# The hull guide now progresses from a simple bar to the real bracket.
for source_module in 'module sloped_hull()'; do
  grep -Fq "$source_module" "$bracket/docs/hull-guide.md"
  grep -Fq "$source_module" "$bracket/docs/hull-guide.html"
done
require_text '## 2. Where does this appear in the real bracket?' "$bracket/docs/hull-guide.md"
require_text 'There is **no preliminary, plain L polygon' "$bracket/docs/chamfer-guide.md"

# Each image is used by exactly the intended guide, with working relative URLs.
check_image() {
  local file="$1" page="$2"
  test -s "$bracket/design/$file.png"
  if [[ "$page" == "readme" ]]; then
    grep -Fq "design/$file.png" "$bracket/readme.md"
    grep -Fq "design/$file.png" "$bracket/readme.html"
  else
    grep -Fq "../design/$file.png" "$bracket/docs/$page.md"
    grep -Fq "../design/$file.png" "$bracket/docs/$page.html"
  fi
}

for stage in 01_profile 02_edge_chamfers 03_nut_pockets 04_print_relief 05_access_plugs 06_installed; do
  check_image "$stage" readme
done
for stage in 01_original_bar 02_wide_layer 03_two_layers 04_hull 05_result; do
  check_image "hull_$stage" hull-guide
done
for stage in layers comparison; do
  check_image "combined_chamfer_$stage" hull-guide
done
for stage in 02_profile_chamfers 02_inside_radius_added 03_extruded_profile 04_convex_outline 05_hull_inputs 06_hull_envelope 07_intersection 08_print_relief 09_final; do
  check_image "chamfer_$stage" chamfer-guide
done

# 2D and 3D rounding alternatives must both be illustrated in the
# standalone polygon guide (never duplicated in the short model walkthrough).
for stage in 01_sharp_2d 02_square_circle_2d 03_piece_2d 04_rounded_2d 05_extruded_2d 06_cube_cylinder_3d 07_piece_3d 08_rounded_3d 09_polygon_points_2d; do
  check_image "corner_$stage" polygon-guide
done

for snippet in 'module corner_piece_2d()' 'module rounded_L_2d()' 'module corner_cube_3d()' 'module corner_piece_3d()' 'module rounded_L_3d()'; do
  grep -Fq "$snippet" "$bracket/docs/polygon-guide.md"
  grep -Fq "$snippet" "$bracket/docs/polygon-guide.html"
done
grep -Fq 'polygon-guide.html' "$bracket/docs/hull-guide.html"
grep -Fq 'chamfer-guide.html' "$bracket/readme.html"
grep -Fq 'polygon-guide.html' "$bracket/readme.html"
if grep -Fq 'design/corner_01_sharp_2d.png' "$bracket/readme.md"; then
  echo "General polygon tutorial leaked into the bracket walkthrough" >&2
  exit 1
fi

echo "Verified generated documentation and all design illustrations."
