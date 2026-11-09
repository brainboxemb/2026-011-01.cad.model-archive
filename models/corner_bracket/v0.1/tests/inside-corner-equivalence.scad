// Regression fixture: compare the current square-minus-circle corner
// with the former 19-point arc. No production CAD depends on this file.
// An empty symmetric difference means the 2D outlines are equivalent.
use <../scad/corner_bracket.scad>

// Match the production defaults. -D can override these to test variants.
inside_corner_radius = 4;
elephant_foot_relief = 0.6;
horizontal_arm_length = 60;
vertical_arm_length = 60;
wall_thickness = 12;
arm_end_chamfer = 3;
outer_corner_chamfer = 6;

legacy_arc = (inside_corner_radius > 0)
    ? [for (a = [180 : -5 : 90])
        [inside_corner_radius + inside_corner_radius * cos(a), -inside_corner_radius + inside_corner_radius * sin(a)]]
    : [[0, 0]];
legacy_tip_top = (elephant_foot_relief > 0)
    ? [[horizontal_arm_length - elephant_foot_relief, 0], [horizontal_arm_length, elephant_foot_relief]]
    : [[horizontal_arm_length, 0]];
legacy_tip_vert = (elephant_foot_relief > 0)
    ? [[-elephant_foot_relief, -vertical_arm_length], [0, -vertical_arm_length + elephant_foot_relief]]
    : [[0, -vertical_arm_length]];

module legacy_profile() {
    polygon(concat(legacy_tip_top, [
        [horizontal_arm_length, wall_thickness - arm_end_chamfer],
        [horizontal_arm_length - arm_end_chamfer, wall_thickness],
        [-wall_thickness + outer_corner_chamfer, wall_thickness],
        [-wall_thickness, wall_thickness - outer_corner_chamfer],
        [-wall_thickness, -vertical_arm_length + arm_end_chamfer],
        [-wall_thickness + arm_end_chamfer, -vertical_arm_length]
    ], legacy_tip_vert, legacy_arc));
}

// The two differences must both be empty. Extrude to make OpenSCAD
// evaluate the result with its full solid geometry engine.
linear_extrude(height = 1)
    union() {
        difference() { bracket_profile_2d(); legacy_profile(); }
        difference() { legacy_profile(); bracket_profile_2d(); }
    }
