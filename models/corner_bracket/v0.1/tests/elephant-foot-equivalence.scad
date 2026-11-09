// Regression fixture for the simplified arm-tip elephant-foot correction.
//
// Production uses ordinary translate()/rotate()/mirror() placement.
// The legacy multmatrix() placement is retained only here as a comparison.

use <../scad/corner_bracket.scad>

bracket_width = 24;
horizontal_arm_length = 60;
vertical_arm_length = 60;
side_edge_chamfer = 2;
elephant_foot_relief = 0.6;
inside_corner_radius = 4;
$fn = 48;

test_view = "xor"; // [current,legacy,xor,tip_effect]

module legacy_tip_prism(A, U, V, direction, length) {
    multmatrix([
        [U[0], V[0], direction[0], A[0]],
        [U[1], V[1], direction[1], A[1]],
        [U[2], V[2], direction[2], A[2]],
        [0, 0, 0, 1]
    ])
        linear_extrude(height = length)
            polygon([
                [-elephant_foot_relief - 1, -1],
                [1, -1],
                [1, elephant_foot_relief + 1]
            ]);
}

module legacy_arm_tip_relief_cuts() {
    s2 = sqrt(2) / 2;
    cut_length = side_edge_chamfer * sqrt(2) + 2;

    if (elephant_foot_relief > 0 && side_edge_chamfer > 0)
        for (mirror_side = [0, 1])
            mirror([0, mirror_side, 0]) {
                legacy_tip_prism(
                    [horizontal_arm_length - side_edge_chamfer - s2,
                     bracket_width / 2 + s2, 0],
                    [s2, s2, 0],
                    [0, 0, 1],
                    [s2, -s2, 0],
                    cut_length
                );

                legacy_tip_prism(
                    [0,
                     bracket_width / 2 - side_edge_chamfer - s2,
                     -vertical_arm_length - s2],
                    [0, s2, -s2],
                    [-1, 0, 0],
                    [0, s2, s2],
                    cut_length
                );
            }
}

module current_relief_body() {
    print_compensated_body();
}

module legacy_relief_body() {
    difference() {
        outer_side_chamfered_body();
        inside_side_relief_cuts();
        legacy_arm_tip_relief_cuts();
    }
}

module no_tip_relief_body() {
    difference() {
        outer_side_chamfered_body();
        inside_side_relief_cuts();
    }
}

module symmetric_difference() {
    union() {
        difference() { children(0); children(1); }
        difference() { children(1); children(0); }
    }
}

if (test_view == "current")
    current_relief_body();
else if (test_view == "legacy")
    legacy_relief_body();
else if (test_view == "xor")
    symmetric_difference() {
        current_relief_body();
        legacy_relief_body();
    }
else if (test_view == "tip_effect")
    symmetric_difference() {
        current_relief_body();
        no_tip_relief_body();
    }
