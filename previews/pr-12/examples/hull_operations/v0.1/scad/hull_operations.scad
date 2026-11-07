// Minimal beam analogue of the Corner Bracket chamfer junction.
//
// This is not a generic rounded beam. It deliberately reproduces the local
// geometry we are trying to understand:
//
//   1. cs bevels the OUTSIDE edges of both printed side faces.
//   2. the bottom contact edge itself is NOT part of that cs envelope.
//   3. ef then bevels that bottom contact edge.
//   4. at each beam end, ef meets the diagonal cs side bevel.
//   5. a short local miter hull blends that junction.
//
// The beam therefore models one straight arm of the real L bracket.

/* [Demo] */
scene = "00_plain"; // [00_plain, 01_cs, 02_problem, 03_miter, 04_fixed, 05_final]

/* [Geometry] */
length = 70;
width = 24;
height = 14;
cs = 3;
ef = 1.2;

/* [Hidden] */
eps = 0.002;
reach = 12;
$fn = 48;

module beam_profile() {
    square([length, height]);
}

// The cs helper deliberately extends BELOW the beam. This is the important
// trick: offset() may bevel the outside end/top edges, while the real bottom
// contact edge at z=0 is recovered by intersection with beam_profile().
module outer_envelope_2d() {
    translate([0, -reach])
        square([length, height + reach]);
}

module plain_beam() {
    rotate([90, 0, 0])
        linear_extrude(height = width, center = true)
            beam_profile();
}

module cs_envelope() {
    rotate([90, 0, 0])
        hull() {
            linear_extrude(height = width - 2 * cs, center = true)
                outer_envelope_2d();
            linear_extrude(height = width, center = true)
                offset(delta = -cs)
                    outer_envelope_2d();
        }
}

// This is the beam after the normal side-edge chamfer.
// Note that the long bottom contact edge is still sharp.
module cs_body() {
    intersection() {
        plain_beam();
        cs_envelope();
    }
}

// Empty space below the contact face. It extends past both beam ends so the
// broad ef hull is concerned only with the long bottom contact edge.
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

// Broad ef cutter on both printed side faces.
module ef_envelope() {
    for (side = [-1, 1])
        hull() {
            opening_layer(side * (width / 2 - ef));
            opening_layer(side * width / 2, ef);
        }
}

// Result BEFORE the local junction correction.
// The broad ef relief runs correctly along the bottom edge, but terminates
// poorly where it reaches the diagonal cs bevel at each beam end.
module pre_miter_body() {
    difference() {
        cs_body();
        ef_envelope();
    }
}

// Generic triangular profile swept along a diagonal. This is the same idea
// used by the real Corner Bracket's relief_corner_miters().
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

// Mirror the right-end construction to the left end.
module miter_corrections() {
    right_end_miters();
    translate([length, 0, 0])
        mirror([1, 0, 0])
            translate([-length, 0, 0])
                right_end_miters();
}

module fixed_body() {
    difference() {
        cs_body();
        ef_envelope();
        miter_corrections();
    }
}

// Crop one lower corner so the cs/ef junction fills the image.
module junction_crop() {
    translate([length - cs - ef - 4, width / 2 - cs - ef - 4, -1])
        cube([cs + ef + 8, cs + ef + 8, ef + 5]);
}

if (scene == "00_plain")
    color("SteelBlue") plain_beam();

else if (scene == "01_cs")
    color("SteelBlue") cs_body();

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
    color("SteelBlue") fixed_body();
