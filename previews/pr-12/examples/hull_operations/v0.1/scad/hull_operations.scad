// Beam analogue of one Corner Bracket arm tip.
//
// This demo deliberately shows each hull() in the same visual pattern:
//
//   A. the TWO input objects, transparent and overlaid;
//   B. the RESULT after hull().
//
// The beam includes the end face as well:
//   * c  : normal upper chamfer on the end profile
//   * cs : normal chamfer around the printed side faces
//   * ef : lower end-profile relief + long bottom contact-edge relief
//
// The final issue is the lower 3D corner where ef reaches the diagonal cs
// side bevel.

/* [Demo] */
scene = "00_plain";
// [00_plain, 01_cs_inputs, 02_cs_result, 03_ef_inputs, 04_ef_result, 05_problem, 06_miter_inputs, 07_fixed]

/* [Geometry] */
length = 70;
width = 24;
height = 14;
c = 3;
cs = 3;
ef = 1.2;

/* [Hidden] */
eps = 0.002;
display_layer = 0.45;
reach = 12;
$fn = 48;

// ---------- Real beam profile ----------

module arm_profile_2d(normal_c = 0, tip_ef = 0) {
    cc = max(0, min(normal_c, min(length, height) / 2));
    ee = max(0, min(tip_ef, min(length, height) / 2));

    polygon([
        [ee, 0],
        [length - ee, 0],
        [length, ee],
        [length, height - cc],
        [length - cc, height],
        [cc, height],
        [0, height - cc],
        [0, ee]
    ]);
}

module plain_beam() {
    rotate([90, 0, 0])
        linear_extrude(height = width, center = true)
            square([length, height]);
}

module profile_extrusion(tip_ef = 0) {
    rotate([90, 0, 0])
        linear_extrude(height = width, center = true)
            arm_profile_2d(c, tip_ef);
}

// ---------- cs hull ----------

// Convex helper for cs. It includes the upper end chamfers, but extends below
// z=0 so the lower contact edge is left to the separate ef operation.
module cs_outer_2d() {
    polygon([
        [0, -reach],
        [length, -reach],
        [length, height - c],
        [length - c, height],
        [c, height],
        [0, height - c]
    ]);
}

// INPUT 1 for cs hull:
// full X/Z outline, but narrower across Y.
module cs_input_full_outline() {
    rotate([90, 0, 0])
        linear_extrude(height = width - 2 * cs, center = true)
            cs_outer_2d();
}

// INPUT 2 for cs hull:
// inset X/Z outline, but full width across Y.
module cs_input_inset_outline() {
    rotate([90, 0, 0])
        linear_extrude(height = width, center = true)
            offset(delta = -cs)
                cs_outer_2d();
}

// RESULT of hull(INPUT 1, INPUT 2).
module cs_envelope() {
    hull() {
        cs_input_full_outline();
        cs_input_inset_outline();
    }
}

// Actual beam after intersecting the cs hull with the real arm profile.
module normal_chamfered_body() {
    intersection() {
        profile_extrusion(0);
        cs_envelope();
    }
}

// Same normal geometry, but with ef also present across the lower end profile.
module body_with_tip_ef() {
    intersection() {
        profile_extrusion(ef);
        cs_envelope();
    }
}

// ---------- ef hull ----------

// Empty region below the straight bottom contact face.
module bottom_opening_2d() {
    translate([-reach, -reach])
        square([length + 2 * reach, reach]);
}

module opening_layer(y, expansion = 0, thickness = eps) {
    translate([0, y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = thickness, center = true)
                offset(delta = expansion)
                    bottom_opening_2d();
}

// INPUT 1 for one ef hull:
// original opening, one ef inward from the printed side.
module ef_input_inner(side, display = false) {
    opening_layer(
        side * (width / 2 - ef),
        0,
        display ? display_layer : eps
    );
}

// INPUT 2 for one ef hull:
// expanded opening on the printed side face.
module ef_input_outer(side, display = false) {
    opening_layer(
        side * width / 2,
        ef,
        display ? display_layer : eps
    );
}

// RESULT for both printed sides.
module ef_side_envelope() {
    for (side = [-1, 1])
        hull() {
            ef_input_inner(side);
            ef_input_outer(side);
        }
}

module pre_miter_body() {
    difference() {
        body_with_tip_ef();
        ef_side_envelope();
    }
}

// ---------- local miter correction ----------

module miter_triangle(A, U, V, D, distance, thickness = eps) {
    multmatrix([[U[0], V[0], D[0], A[0]],
                [U[1], V[1], D[1], A[1]],
                [U[2], V[2], D[2], A[2]],
                [0, 0, 0, 1]])
        translate([0, 0, distance])
            linear_extrude(height = thickness)
                polygon([[-ef - 1, -1], [1, -1], [1, ef + 1]]);
}

module relief_miter_hull(A, U, V, D, len) {
    hull() {
        miter_triangle(A, U, V, D, 0);
        miter_triangle(A, U, V, D, len);
    }
}

module right_end_miter_inputs(side, display = false) {
    s2 = sqrt(2) / 2;
    A = [length - cs - s2, side * (width / 2 + s2), 0];
    U = [s2, side * s2, 0];
    V = [0, 0, 1];
    D = [s2, -side * s2, 0];
    len = cs * sqrt(2) + 2;
    thick = display ? display_layer : eps;

    miter_triangle(A, U, V, D, 0, thick);
    miter_triangle(A, U, V, D, len, thick);
}

module right_end_miters() {
    s2 = sqrt(2) / 2;

    for (side = [-1, 1])
        relief_miter_hull(
            [length - cs - s2, side * (width / 2 + s2), 0],
            [s2, side * s2, 0],
            [0, 0, 1],
            [s2, -side * s2, 0],
            cs * sqrt(2) + 2
        );
}

module miter_corrections() {
    right_end_miters();

    translate([length, 0, 0])
        mirror([1, 0, 0])
            translate([-length, 0, 0])
                right_end_miters();
}

module fixed_body() {
    difference() {
        body_with_tip_ef();
        ef_side_envelope();
        miter_corrections();
    }
}

module junction_crop() {
    translate([length - cs - ef - 4, width / 2 - cs - ef - 4, -1])
        cube([cs + ef + 8, cs + ef + 8, ef + 5]);
}

// ---------- scenes ----------

if (scene == "00_plain") {
    color("SteelBlue")
        plain_beam();
}

else if (scene == "01_cs_inputs") {
    // Exactly the two objects passed to cs hull(), shown transparently.
    color("SteelBlue", 0.38)
        cs_input_full_outline();
    color("DarkOrange", 0.38)
        cs_input_inset_outline();
}

else if (scene == "02_cs_result") {
    color("SteelBlue")
        normal_chamfered_body();
}

else if (scene == "03_ef_inputs") {
    // Keep the already chamfered beam faintly visible as context.
    color("LightSlateGray", 0.16)
        body_with_tip_ef();

    // Show the two actual inputs for ONE side's ef hull().
    // The opposite side is identical.
    color("SteelBlue", 0.42)
        ef_input_inner(1, true);
    color("DarkOrange", 0.42)
        ef_input_outer(1, true);
}

else if (scene == "04_ef_result") {
    color("SteelBlue")
        pre_miter_body();
}

else if (scene == "05_problem") {
    color("SteelBlue")
        intersection() {
            pre_miter_body();
            junction_crop();
        }
}

else if (scene == "06_miter_inputs") {
    // The correction is itself another hull: show its two triangular inputs.
    color("LightSlateGray", 0.16)
        intersection() {
            pre_miter_body();
            junction_crop();
        }

    color("SteelBlue", 0.48)
        intersection() {
            right_end_miter_inputs(1, true);
            junction_crop();
        }
}

else {
    color("DarkOrange")
        intersection() {
            fixed_body();
            junction_crop();
        }
}
