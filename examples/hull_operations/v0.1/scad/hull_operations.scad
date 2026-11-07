// Beam analogue of one Corner Bracket arm tip.
//
// The important point is that the end face is part of the story too:
//
//   * c  : normal upper chamfer on the END profile (kopse kant)
//   * cs : normal chamfer around the printed SIDE faces
//   * ef : lower end-profile relief AND the long bottom contact-edge relief
//
// The difficult 3D junction is where the long ef relief reaches the diagonal
// cs side bevel at the lower end corner. A small local miter hull corrects it.

/* [Demo] */
scene = "00_plain"; // [00_plain, 01_normal_chamfers, 02_problem, 03_miter, 04_fixed, 05_final]

/* [Geometry] */
length = 70;
width = 24;
height = 14;
c = 3;
cs = 3;
ef = 1.2;

/* [Hidden] */
eps = 0.002;
reach = 12;
$fn = 48;

// 2D arm profile in X/Z.
//
// normal_c controls the normal chamfer at BOTH upper end corners.
// tip_ef controls the lower end relief at BOTH lower end corners.
// The latter is the part that was missing from the earlier beam demo.
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

// Convex helper for cs. It includes the upper end chamfers, but deliberately
// extends below z=0. Intersecting it with the real profile therefore leaves the
// bottom contact edge for the separate ef operation.
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

module profile_extrusion(tip_ef = 0) {
    rotate([90, 0, 0])
        linear_extrude(height = width, center = true)
            arm_profile_2d(c, tip_ef);
}

module plain_beam() {
    rotate([90, 0, 0])
        linear_extrude(height = width, center = true)
            square([length, height]);
}

module cs_envelope() {
    rotate([90, 0, 0])
        hull() {
            linear_extrude(height = width - 2 * cs, center = true)
                cs_outer_2d();
            linear_extrude(height = width, center = true)
                offset(delta = -cs)
                    cs_outer_2d();
        }
}

// Normal geometry before elephant-foot relief:
// - upper end-profile chamfer c IS present on the kopse kanten;
// - side-face chamfer cs IS present;
// - lower end-profile relief ef is NOT present yet.
module normal_chamfered_body() {
    intersection() {
        profile_extrusion(0);
        cs_envelope();
    }
}

// Same normal chamfers, now also with the lower end-profile ef chamfers.
// These lower diagonal faces run across the complete beam width, so the
// elephant-foot correction is represented on the kopse kanten as well.
module body_with_tip_ef() {
    intersection() {
        profile_extrusion(ef);
        cs_envelope();
    }
}

// Empty space below the straight bottom contact face. It extends beyond both
// ends because the end-profile ef chamfers are already part of arm_profile_2d().
module bottom_opening_2d() {
    translate([-reach, -reach])
        square([length + 2 * reach, reach]);
}

module opening_layer(y, expansion = 0) {
    translate([0, y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = eps, center = true)
                offset(delta = expansion)
                    bottom_opening_2d();
}

// Broad ef relief along BOTH long bottom edges on the printed side faces.
module ef_side_envelope() {
    for (side = [-1, 1])
        hull() {
            opening_layer(side * (width / 2 - ef));
            opening_layer(side * width / 2, ef);
        }
}

// This is the real problem state:
// - c exists at the upper end faces,
// - cs exists around the side faces,
// - ef exists across the lower end faces,
// - ef also runs along the long lower contact edges,
// but the endpoint of the broad ef side relief does not make the desired
// continuous miter against the diagonal cs side bevel.
module pre_miter_body() {
    difference() {
        body_with_tip_ef();
        ef_side_envelope();
    }
}

// Small triangular cutter swept along the local diagonal where cs and ef meet.
// This mirrors the idea of relief_corner_miters() in the actual bracket.
module relief_miter_hull(A, U, V, D, len) {
    module triangle_at(distance) {
        multmatrix([[U[0], V[0], D[0], A[0]],
                    [U[1], V[1], D[1], A[1]],
                    [U[2], V[2], D[2], A[2]],
                    [0, 0, 0, 1]])
            translate([0, 0, distance])
                linear_extrude(height = eps)
                    polygon([[-ef - 1, -1], [1, -1], [1, ef + 1]]);
    }

    hull() {
        triangle_at(0);
        triangle_at(len);
    }
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

// Focus on one lower end corner. This contains all three relevant surfaces:
// the kopse ef face, the long ef side relief and the diagonal cs side bevel.
module junction_crop() {
    translate([length - cs - ef - 4, width / 2 - cs - ef - 4, -1])
        cube([cs + ef + 8, cs + ef + 8, ef + 5]);
}

if (scene == "00_plain")
    color("SteelBlue")
        plain_beam();

else if (scene == "01_normal_chamfers")
    color("SteelBlue")
        normal_chamfered_body();

else if (scene == "02_problem")
    color("SteelBlue")
        intersection() {
            pre_miter_body();
            junction_crop();
        }

else if (scene == "03_miter")
    color("IndianRed")
        intersection() {
            miter_corrections();
            junction_crop();
        }

else if (scene == "04_fixed")
    color("DarkOrange")
        intersection() {
            fixed_body();
            junction_crop();
        }

else
    color("SteelBlue")
        fixed_body();
