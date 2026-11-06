#!/usr/bin/env bash
# Runs inside the shared CAD image, from models/corner_bracket/v0.1.
set -euo pipefail

render() {
  local file="$1" variable="$2" stage="$3" output="$4" imgsize="$5"
  xvfb-run -a openscad --imgsize="$imgsize" --viewall --autocenter \
    -D "$variable=\"$stage\"" -o "design/$output.png" "scad/$file"
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

# Seven stages: circular outer corners vs the sampled inner arc of the L.
for stage in 01_four_circles 02_hull_of_circles 03_sharp_L 04_circle_guide 05_arc_points 06_rounded_L 07_hull_fills_corner; do
  render rounding_explained.scad demo_stage "$stage" "rounding_$stage" "720,450"
done

# Nine clear examples of a concave L fillet: 2D square/circle, 3D
# cube/cylinder, and the existing point-list polygon approach.
for stage in 01_sharp_2d 02_square_circle_2d 03_piece_2d 04_rounded_2d 05_extruded_2d 06_cube_cylinder_3d 07_piece_3d 08_rounded_3d 09_polygon_points_2d; do
  render inside_corner_methods.scad demo_stage "$stage" "corner_$stage" "720,450"
done
