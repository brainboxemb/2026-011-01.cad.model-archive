// Regression fixture for elephant-foot print compensation.
//
// Production now uses explicit cut geometry because the unwanted material is
// simpler to describe directly. The former hull-based implementation remains
// here only as an independent comparison reference.
//
// CI checks that switching back to the simpler direct cutters stays within the
// previously accepted whole-part tolerance and keeps the same bounding box.

use <../scad/corner_bracket.scad>

// Match production defaults. CI overrides these values.
bracket_width = 20;
horizontal_arm_length = 40;
vertical_arm_length = 40;
side_edge_chamfer = 2;
elephant_foot_relief = 0.6;
inside_corner_radius = 2;
$fn = 48;

test_view = "xor"; // [direct,former_hull,xor,tip_xor,tip_xor_without_miters]

// ---------- Former hull implementation, retained only for regression ----------

module former_inside_opening_2d() {
    reach = max(5, side_edge_chamfer + elephant_foot_relief + 1);

    difference() {
        translate([0, -vertical_arm_length - reach])
            square([
                horizontal_arm_length + reach,
                vertical_arm_length + reach
            ]);

        if (inside_corner_radius > 0)
            inside_corner_fill_2d(inside_corner_radius);
    }
}

module former_opening_layer(y, expansion = 0) {
    translate([0, y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = 0.002, center = true)
                offset(delta = expansion)
                    former_inside_opening_2d();
}

module former_relief_opening_hulls() {
    if (elephant_foot_relief > 0)
        for (side = [-1, 1])
            hull() {
                former_opening_layer(
                    side * (bracket_width / 2 - elephant_foot_relief)
                );
                former_opening_layer(
                    side * bracket_width / 2,
                    elephant_foot_relief
                );
            }
}

module former_miter_hull(A, U, V, direction, length) {
    module triangle_at(distance) {
        multmatrix([
            [U[0], V[0], direction[0], A[0]],
            [U[1], V[1], direction[1], A[1]],
            [U[2], V[2], direction[2], A[2]],
            [0, 0, 0, 1]
        ])
            translate([0, 0, distance])
                linear_extrude(height = 0.001)
                    polygon([
                        [-elephant_foot_relief - 1, -1],
                        [1, -1],
                        [1, elephant_foot_relief + 1]
                    ]);
    }

    hull() {
        triangle_at(0);
        triangle_at(length);
    }
}

module former_relief_corner_miters() {
    s2 = sqrt(2) / 2;

    if (elephant_foot_relief > 0 && side_edge_chamfer > 0)
        for (mirror_side = [0, 1])
            mirror([0, mirror_side, 0]) {
                former_miter_hull(
                    [
                        horizontal_arm_length - side_edge_chamfer - s2,
                        bracket_width / 2 + s2,
                        0
                    ],
                    [s2, s2, 0],
                    [0, 0, 1],
                    [s2, -s2, 0],
                    side_edge_chamfer * sqrt(2) + 2
                );

                former_miter_hull(
                    [
                        0,
                        bracket_width / 2 - side_edge_chamfer - s2,
                        -vertical_arm_length - s2
                    ],
                    [0, s2, -s2],
                    [-1, 0, 0],
                    [0, s2, s2],
                    side_edge_chamfer * sqrt(2) + 2
                );
            }
}

module former_hull_print_compensated_body(include_miters = true) {
    difference() {
        outer_side_chamfered_body();
        former_relief_opening_hulls();

        if (include_miters)
            former_relief_corner_miters();
    }
}

module former_hull_bracket(include_miters = true) {
    difference() {
        former_hull_print_compensated_body(include_miters);
        top_fastener_cut();
        vertical_fastener_cut();
    }
}

// Isolate the four small arm-tip regions where the print relief meets the
// outer side chamfer. This catches visually noticeable local differences.
module tip_regions() {
    for (mirror_side = [0, 1])
        mirror([0, mirror_side, 0]) {
            translate([
                horizontal_arm_length - side_edge_chamfer
                    - elephant_foot_relief - 3,
                bracket_width / 2 - side_edge_chamfer
                    - elephant_foot_relief - 3,
                -1
            ])
                cube([
                    side_edge_chamfer + elephant_foot_relief + 5,
                    side_edge_chamfer + elephant_foot_relief + 5,
                    elephant_foot_relief + 2
                ]);

            translate([
                -1,
                bracket_width / 2 - side_edge_chamfer
                    - elephant_foot_relief - 3,
                -vertical_arm_length - 1
            ])
                cube([
                    elephant_foot_relief + 2,
                    side_edge_chamfer + elephant_foot_relief + 5,
                    side_edge_chamfer + elephant_foot_relief + 5
                ]);
        }
}

module symmetric_difference() {
    union() {
        difference() {
            bracket();
            children();
        }
        difference() {
            children();
            bracket();
        }
    }
}

if (test_view == "direct")
    bracket();

else if (test_view == "former_hull")
    former_hull_bracket();

else if (test_view == "xor")
    symmetric_difference()
        former_hull_bracket();

else if (test_view == "tip_xor")
    intersection() {
        symmetric_difference()
            former_hull_bracket();
        tip_regions();
    }

else if (test_view == "tip_xor_without_miters")
    intersection() {
        symmetric_difference()
            former_hull_bracket(false);
        tip_regions();
    }
