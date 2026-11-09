#!/usr/bin/env bash
# Fail the build if generated documentation, STL files, or tutorial
# illustrations are absent from NopSCADlib outputs.
set -euo pipefail
trap 'echo "Validation failed on line $LINENO: $BASH_COMMAND" >&2' ERR

test -s "docs/design-concepts.md"
test -s "docs/design-concepts.html"
grep -Fq 'OpenSCAD design concepts' "docs/design-concepts.html"
grep -Fq 'A shape can describe material that stays' "docs/design-concepts.html"
grep -Fq 'A shape can describe material that must be removed' "docs/design-concepts.html"
grep -Fq 'A shape can describe the final boundary' "docs/design-concepts.html"
test -s "docs/design-concepts.scad"
for stage in 01_keep 02_cut 03_clip 04_hull_keep 05_hull_cut 06_convexity 07_decompose; do
  test -s "docs/figures/concept_$stage.png"
  grep -Fq "figures/concept_$stage.png" "docs/design-concepts.md"
  grep -Fq "figures/concept_$stage.png" "docs/design-concepts.html"
done
grep -Fq 'What do I want this temporary shape to do?' "docs/design-concepts.html"
grep -Fq 'A global hull cannot keep a concave notch open' "docs/design-concepts.html"

spacer="examples/spacer/v0.1"
test -s "$spacer/stls/spacer.stl"
test -s "$spacer/stls/spacer.png"
test -s "$spacer/assemblies/main_assembled.png"
test -s "$spacer/bom/bom.json"
test -s "$spacer/readme.html"
grep -q 'Example spacer' "$spacer/readme.md"

tube="examples/rounded-rectangular-tube/v0.1"
test -s "$tube/scad/rounded_rectangular_tube.scad"
test -s "$tube/README.md"
test -s "$tube/readme.html"
test -s "$tube/figures/rounded_rectangular_tube.png"
test -s "$tube/design/rounded_rectangular_tube_explained.scad"
for stage in \
  01_profiles 02_outer_chamfer_inputs 03_outer_hull 04_hollow_tube \
  05_inner_chamfer_inputs 06_inner_chamfer_cut 07_bottom_chamfer_result \
  08_final 09_chamfer_closeup; do
  test -s "$tube/design/tube_$stage.png"
  grep -Fq "design/tube_$stage.png" "$tube/README.md"
  grep -Fq "design/tube_$stage.png" "$tube/readme.html"
done
grep -Fq 'Rounded rectangular tube with end chamfers' "$tube/README.md"
grep -Fq 'Create the inside chamfer as a cutting volume' "$tube/readme.html"
grep -Fq 'Why the chamfer construction stays simple' "$tube/readme.html"
grep -Fq 'The shell itself is therefore not created by one complicated hull' "$tube/readme.html"
grep -Fq 'figures/rounded_rectangular_tube.png' "$tube/readme.html"

lbracket="examples/rounded-l-bracket/v0.1"
test -s "$lbracket/scad/rounded_l_bracket.scad"
test -s "$lbracket/README.md"
test -s "$lbracket/readme.html"
test -s "$lbracket/figures/rounded_l_bracket.png"
test -s "$lbracket/design/rounded_l_bracket_explained.scad"
for stage in \
  01_outer_profile 02_inner_profile 03_shell_profile 04_outer_chamfer_inputs \
  05_outer_body 06_inner_chamfer_inputs 07_inner_chamfer_cut 08_before_trim \
  09_final_trim 10_chamfer_closeup; do
  test -s "$lbracket/design/lbracket_$stage.png"
  grep -Fq "design/lbracket_$stage.png" "$lbracket/README.md"
  grep -Fq "design/lbracket_$stage.png" "$lbracket/readme.html"
done
grep -Fq 'Rounded L bracket with end chamfers' "$lbracket/README.md"
grep -Fq 'Why the deliberate overhang is useful' "$lbracket/readme.html"
grep -Fq 'Trim the leg ends' "$lbracket/readme.html"
grep -Fq 'figures/rounded_l_bracket.png' "$lbracket/readme.html"

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
# Production source must use descriptive names and direct print-relief cuts.
for source_module in \
  'module inside_corner_fill_2d(r)' \
  'module base_profile_2d()' \
  'module bracket_profile_2d()' \
  'module profile_body()' \
  'module outer_chamfer_envelope_2d()' \
  'module outer_side_chamfer_keep_envelope()' \
  'module outer_side_chamfered_body()' \
  'module elephant_foot_relief_cuts()' \
  'module print_compensated_body()' \
  'module top_fastener_cut()' \
  'module vertical_fastener_cut()'; do
  grep -Fq "$source_module" "$bracket/scad/corner_bracket.scad"
done

for parameter in \
  bracket_width wall_thickness horizontal_arm_length vertical_arm_length \
  arm_end_chamfer outer_corner_chamfer side_edge_chamfer \
  elephant_foot_relief inside_corner_radius; do
  grep -Eq "^$parameter[[:space:]]*=" "$bracket/scad/corner_bracket.scad"
done

if grep -Eq '^(W|t|armH|armV|c|ce|cs|ef|r_in)[[:space:]]*=' "$bracket/scad/corner_bracket.scad"; then
  echo "Old cryptic bracket parameter name returned to production source" >&2
  exit 1
fi

if grep -Eq 'inside_relief_envelope|relief_corner_miters|module opening_layer' "$bracket/scad/corner_bracket.scad"; then
  echo "Former hull-based print relief returned to production source" >&2
  exit 1
fi

grep -Fq 'former_relief_opening_hulls' "$bracket/tests/elephant-foot-equivalence.scad"
grep -Fq 'module elephant_foot_relief_cuts()' "$bracket/readme.md"
grep -Fq 'module outer_side_chamfer_keep_envelope()' "$bracket/readme.md"

if grep -Fq 'corner_arc = (inside_corner_radius > 0)' "$bracket/scad/corner_bracket.scad"; then
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

# The generated bracket manual must explain the current keep/cut architecture.
for svg in elephant-foot-section elephant-foot-edges; do
  test -s "$bracket/figures/$svg.svg"
  grep -Fq "figures/$svg.svg" "$bracket/readme.md"
  grep -Fq "figures/$svg.svg" "$bracket/readme.html"
done

grep -Fq '### 2. Create the outside side-edge chamfer' "$bracket/readme.md"
grep -Fq '### 3. Remove the fastener spaces' "$bracket/readme.md"
grep -Fq '### 4. Remove elephant-foot print compensation' "$bracket/readme.md"
grep -Fq 'elephant_foot_relief_cuts()' "$bracket/readme.md"
grep -Fq 'outer_side_chamfer_keep_envelope()' "$bracket/readme.md"
grep -Fq 'top_fastener_cut()' "$bracket/readme.md"
grep -Fq 'vertical_fastener_cut()' "$bracket/readme.md"
grep -Fq '<pre><code>' "$bracket/readme.html"

if grep -Fq 'inside_relief_envelope()' "$bracket/readme.md"; then
  echo "Obsolete hull-relief explanation returned to generated manual" >&2
  exit 1
fi

# Focused guides must use current production terminology.
grep -Fq '## 6. Why elephant-foot relief does not use hull() anymore' "$bracket/docs/hull-guide.md"
grep -Fq 'module outer_side_chamfer_keep_envelope()' "$bracket/docs/hull-guide.md"
grep -Fq 'module outer_side_chamfered_body()' "$bracket/docs/hull-guide.md"
grep -Fq 'elephant_foot_relief_cuts()' "$bracket/docs/chamfer-guide.md"
grep -Fq 'explicit cutter volumes' "$bracket/docs/chamfer-guide.md"

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

for stage in 01_profile 02_outer_side_chamfers 03_fastener_cuts 04_print_relief 05_access_plugs 06_installed; do
  check_image "$stage" readme
done
for stage in 01_original_bar 02_wide_layer 03_two_layers 04_hull 05_result; do
  check_image "hull_$stage" hull-guide
done
for stage in layers comparison; do
  check_image "combined_chamfer_$stage" hull-guide
done
for stage in 01_plain_l 02_profile_chamfers 03_profile_body 04_outer_envelope 05_side_chamfer_inputs 06_side_chamfer_envelope 07_side_chamfered_body 08_elephant_foot_cuts 09_print_compensated_body 10_final; do
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
