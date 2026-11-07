#!/usr/bin/env bash
# Runs inside the shared CAD image, from models/corner_bracket/v0.1.
set -euo pipefail

render() {
  local file="$1" variable="$2" stage="$3" output="$4" imgsize="$5"
  xvfb-run -a openscad --imgsize="$imgsize" --viewall --autocenter \
    -D "$variable=\"$stage\"" -o "design/$output.png" "design/$file"
  test -s "design/$output.png"
}

# Six stages of the real parametric bracket.
for stage in 01_profile 02_edge_chamfers 03_nut_pockets 04_print_relief 05_access_plugs 06_installed; do
  render design.scad design_step "$stage" "$stage" "800,600"
done

# Five stages of the simple bar hull() tutorial.
for stage in 01_original_bar 02_wide_layer 03_two_layers 04_hull 05_result; do
  render hull_explained.scad demo_stage "$stage" "hull_$stage" "720,450"
done


# Nine clear examples of a concave L fillet: 2D square/circle, 3D
# cube/cylinder, and the existing point-list polygon approach.
for stage in 01_sharp_2d 02_square_circle_2d 03_piece_2d 04_rounded_2d 05_extruded_2d 06_cube_cylinder_3d 07_piece_3d 08_rounded_3d 09_polygon_points_2d; do
  render inside_corner_methods.scad demo_stage "$stage" "corner_$stage" "720,450"
done

# Seven stages cover the actual profile and outside cs hull. The complete
# elephant-foot hull gets its own dedicated sequence below.
for stage in 02_profile_chamfers 02_inside_radius_added 03_extruded_profile 04_convex_outline 05_hull_inputs 06_hull_envelope 07_intersection; do
  render chamfer_explained.scad chamfer_step "$stage" "chamfer_$stage" "720,450"
done


# Start with the complete bracket, then zoom into the local EF hull experiment.
for stage in \
  00_whole_main_only \
  00_whole_problem_points \
  00_whole_working \
  01_opening_profile \
  02_inner_main_input \
  03_outer_main_input \
  04_both_main_inputs \
  05_main_hull \
  06_main_result \
  07_missing_tip_volume \
  08_reference_relief_volume \
  09_reference_result \
  10_exact_reference_inputs \
  11_exact_two_surface_hull \
  12_exact_candidate_result \
  13_exact_candidate_xor \
  14_exact_candidate_overcut \
  15_exact_candidate_undercut; do
  render ef_hull_experiment.scad experiment_step "$stage" "efh_$stage" "900,600"
done
