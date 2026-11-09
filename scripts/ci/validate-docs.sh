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
test ! -e "$bracket/stls/access_plugs.stl"
test -s "$bracket/assemblies/main_assembled.png"
test -s "$bracket/bom/bom.json"
test -s "$bracket/readme.md"
test -s "$bracket/readme.html"
test -s "$bracket/printme.html"
grep -q "Corner bracket" "$bracket/readme.md"

# Exactly one printable model source plus the inspection helper.
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

# Production source must reflect the simplified architecture.
for source_module in \
  'module inside_corner_fill_2d(r)' \
  'module base_profile_2d()' \
  'module bracket_profile_2d()' \
  'module profile_body()' \
  'module outer_side_chamfer_keep_envelope()' \
  'module outer_side_chamfered_body()' \
  'module inside_opening_2d()' \
  'module inside_side_relief_layer(y, expansion = 0)' \
  'module inside_side_relief_cuts()' \
  'module arm_tip_relief_wedge(length)' \
  'module arm_tip_relief_cuts()' \
  'module print_compensated_body()' \
  'module countersunk_bolt_cut()' \
  'module bolt_cuts()'; do
  grep -Fq "$source_module" "$bracket/scad/corner_bracket.scad"
done

for parameter in \
  bracket_width wall_thickness horizontal_arm_length vertical_arm_length \
  arm_end_chamfer outer_corner_chamfer side_edge_chamfer \
  elephant_foot_relief inside_corner_radius bolts_per_arm bolt_diameter bolt_length bolt_hole_edge_relief; do
  grep -Eq "^$parameter[[:space:]]*=" "$bracket/scad/corner_bracket.scad"
done

grep -Eq "^bolts_per_arm[[:space:]]*=[[:space:]]*2" "$bracket/scad/corner_bracket.scad"
grep -Eq "^bolt_diameter[[:space:]]*=[[:space:]]*5" "$bracket/scad/corner_bracket.scad"
grep -Eq "^bolt_length[[:space:]]*=[[:space:]]*30" "$bracket/scad/corner_bracket.scad"
grep -Eq "^bolt_hole_edge_relief[[:space:]]*=[[:space:]]*0.2" "$bracket/scad/corner_bracket.scad"

# The active source must not drift back to the captive-nut/plug design or the
# hard-to-read multmatrix arm-tip placement.
for obsolete in "module nut_top" "module nut_side" "module plug_local" "module plugs_print_pair" "module arm_end_relief_cuts" "counterbore_flare"; do
  if grep -Fq "$obsolete" "$bracket/scad/corner_bracket.scad"; then
    echo "Obsolete bracket geometry returned: $obsolete" >&2
    exit 1
  fi
done

if grep -Eq '^[[:space:]]*multmatrix[(]' "$bracket/scad/corner_bracket.scad"; then
  echo "multmatrix() returned to production arm-tip geometry" >&2
  exit 1
fi

# The legacy multmatrix transform is deliberately retained only in the regression fixture.
grep -Fq "module legacy_tip_prism" "$bracket/tests/elephant-foot-equivalence.scad"
grep -Fq "multmatrix([" "$bracket/tests/elephant-foot-equivalence.scad"

# Active guides.
for page in mounting-options hull-guide polygon-guide chamfer-guide; do
  test -s "$bracket/docs/$page.md"
  test -s "$bracket/docs/$page.html"
  grep -Fq "docs/$page.html" "$bracket/readme.md"
  grep -Fq "docs/$page.html" "$bracket/readme.html"
done

grep -Fq "four M5 DIN 7991-style countersunk bolts" "$bracket/readme.md"
grep -Fq "inside_side_relief_cuts()" "$bracket/readme.md"
grep -Fq "arm_tip_relief_cuts()" "$bracket/readme.md"
grep -Fq "multmatrix()" "$bracket/readme.md"
grep -Fq "two bolts per arm" "$bracket/docs/mounting-options.md"
grep -Fq "M5 × 30" "$bracket/docs/mounting-options.md"
grep -Fq "bolt_hole_edge_relief" "$bracket/docs/mounting-options.md"
grep -Fq "flat cylindrical edge relief" "$bracket/docs/mounting-options.md"
grep -Fq "one continuous opening hull per broad side" "$bracket/docs/chamfer-guide.md"
grep -Fq 'It does **not** use `multmatrix()`.' "$bracket/docs/hull-guide.md"

# Walkthrough images used by the generated manual.
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

for stage in 01_profile 02_outer_side_chamfers 03_side_relief 04_bolt_cuts 05_final 06_installed; do
  check_image "$stage" readme
done

for stage in 01_original_bar 02_wide_layer 03_two_layers 04_hull 05_result; do
  check_image "hull_$stage" hull-guide
done

for stage in layers comparison; do
  check_image "combined_chamfer_$stage" hull-guide
done

for stage in 01_plain_l 02_profile_chamfers 03_profile_body 04_outer_envelope 05_side_chamfer_inputs 06_side_chamfer_envelope 07_side_chamfered_body 08_continuous_side_relief 09_print_compensated_body 10_final; do
  check_image "chamfer_$stage" chamfer-guide
done

for stage in 01_sharp_2d 02_square_circle_2d 03_piece_2d 04_rounded_2d 05_extruded_2d 06_cube_cylinder_3d 07_piece_3d 08_rounded_3d 09_polygon_points_2d; do
  check_image "corner_$stage" polygon-guide
done

grep -Fq "polygon-guide.html" "$bracket/docs/hull-guide.html"
grep -Fq "chamfer-guide.html" "$bracket/readme.html"
grep -Fq "mounting-options.html" "$bracket/readme.html"

echo "Verified generated documentation and all design illustrations."
