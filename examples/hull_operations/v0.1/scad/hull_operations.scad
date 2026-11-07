// Beam experiment: build cs and ef with the same basic idea.
//
// Each operation is shown as:
//   1. TWO transparent input solids;
//   2. hull() of those solids;
//   3. intersection() with the beam.
//
// cs and ef use different directions, but the construction principle is the
// same. This lets us inspect whether their lower corner joins naturally,
// without adding a special local miter correction.

/* [Demo] */
scene = "00_plain"; // [00_plain, 01_cs_inputs, 02_cs_result, 03_ef_inputs, 04_ef_result, 05_combined, 06_corner, 07_miter_inputs, 08_fixed]

/* [Geometry] */
length = 70;
width = 24;
height = 14;
c = 3;
cs = 3;
ef = 1.2;

/* [Hidden] */
eps = 0.02;
reach = 12;
$fn = 48;

// ---------- Base beam ----------

// The normal end-profile chamfer c is part of the beam itself.
// The lower end remains square here; ef will be created by its own hull.
module beam_profile_2d() {
    polygon([
        [0, 0],
        [length, 0],
        [length, height - c],
        [length - c, height],
        [c, height],
        [0, height - c]
    ]);
}

module beam() {
    rotate([90, 0, 0])
        linear_extrude(height = width, center = true)
            beam_profile_2d();
}

module plain_beam() {
    cube([length, width, height]);
}

// ---------- cs: chamfer around the printed side faces ----------

// Extend below z=0 so the cs helper does NOT chamfer the bottom edge.
// The bottom is deliberately reserved for ef.
module cs_outline_2d() {
    polygon([
        [0, -reach],
        [length, -reach],
        [length, height - c],
        [length - c, height],
        [c, height],
        [0, height - c]
    ]);
}

// cs INPUT 1:
// full X/Z outline, but stopping cs before each printed side face.
module cs_input_inner() {
    rotate([90, 0, 0])
        linear_extrude(height = width - 2 * cs, center = true)
            cs_outline_2d();
}

// cs INPUT 2:
// inset X/Z outline, extending all the way to both printed side faces.
module cs_input_outer() {
    rotate([90, 0, 0])
        linear_extrude(height = width, center = true)
            offset(delta = -cs)
                cs_outline_2d();
}

module cs_hull() {
    hull() {
        cs_input_inner();
        cs_input_outer();
    }
}

module cs_body() {
    intersection() {
        beam();
        cs_hull();
    }
}

// ---------- ef: chamfer around the complete bottom perimeter ----------
//
// This is now intentionally the SAME STYLE of construction:
// two solids -> hull() -> intersection().
//
// At z=0 the footprint is inset by ef on ALL four sides, so the elephant-foot
// relief includes both long bottom edges AND both kopse bottom edges.
// At z=ef the full beam footprint is restored.

// ef INPUT 1:
// thin bottom footprint, inset by ef around the complete perimeter.
module ef_input_bottom() {
    translate([ef, -width / 2 + ef, 0])
        cube([length - 2 * ef, width - 2 * ef, eps]);
}

// ef INPUT 2:
// full footprint starting ef above the print bed and continuing upward.
// Using a volume rather than a thin layer makes the hull itself the complete
// envelope that can be intersected with the beam.
module ef_input_upper() {
    translate([0, -width / 2, ef])
        cube([length, width, height + reach]);
}

module ef_hull() {
    hull() {
        ef_input_bottom();
        ef_input_upper();
    }
}

module ef_body() {
    intersection() {
        beam();
        ef_hull();
    }
}

// Apply BOTH independently constructed envelopes to the same real beam.
module combined_body() {
    intersection() {
        beam();
        cs_hull();
        ef_hull();
    }
}

// Focus on the lower-right/front corner where the ef bottom hull reaches the
// diagonal cs side bevel. No special correction is added in this experiment.
module corner_crop() {
    translate([length - cs - ef - 4, width / 2 - cs - ef - 4, -1])
        cube([cs + ef + 8, cs + ef + 8, cs + ef + 5]);
}

// ---------- local junction correction ----------
//
// The separate cs_hull() and ef_hull() are both correct on their own, but
// intersection() does not "blend" their meeting corner. It simply keeps the
// material common to both envelopes, leaving the small flat termination seen
// in scene 06_corner.
//
// The correction is therefore deliberately local: hull two tiny triangular
// profiles along the diagonal cs/ef junction and subtract that hull.

module miter_triangle(A, U, V, D, distance, thickness = eps) {
    multmatrix([[U[0], V[0], D[0], A[0]],
                [U[1], V[1], D[1], A[1]],
                [U[2], V[2], D[2], A[2]],
                [0, 0, 0, 1]])
        translate([0, 0, distance])
            linear_extrude(height = thickness)
                polygon([[-ef - 1, -1], [1, -1], [1, ef + 1]]);
}

module right_front_miter_inputs(display = false) {
    s2 = sqrt(2) / 2;
    A = [length - cs - s2, width / 2 + s2, 0];
    U = [s2, s2, 0];
    V = [0, 0, 1];
    D = [s2, -s2, 0];
    len = cs * sqrt(2) + 2;
    thick = display ? 0.35 : eps;

    miter_triangle(A, U, V, D, 0, thick);
    miter_triangle(A, U, V, D, len, thick);
}

module right_front_miter_hull() {
    s2 = sqrt(2) / 2;
    A = [length - cs - s2, width / 2 + s2, 0];
    U = [s2, s2, 0];
    V = [0, 0, 1];
    D = [s2, -s2, 0];
    len = cs * sqrt(2) + 2;

    hull() {
        miter_triangle(A, U, V, D, 0);
        miter_triangle(A, U, V, D, len);
    }
}

module all_miter_hulls() {
    // Right/front.
    right_front_miter_hull();

    // Right/back.
    mirror([0, 1, 0])
        right_front_miter_hull();

    // Left/front and left/back.
    translate([length, 0, 0])
        mirror([1, 0, 0])
            translate([-length, 0, 0]) {
                right_front_miter_hull();
                mirror([0, 1, 0])
                    right_front_miter_hull();
            }
}

module fixed_body() {
    difference() {
        combined_body();
        all_miter_hulls();
    }
}

// ---------- scenes ----------

if (scene == "00_plain") {
    color("SteelBlue")
        beam();
}

else if (scene == "01_cs_inputs") {
    color("SteelBlue", 0.36)
        cs_input_inner();
    color("DarkOrange", 0.36)
        cs_input_outer();
}

else if (scene == "02_cs_result") {
    color("SteelBlue")
        cs_body();
}

else if (scene == "03_ef_inputs") {
    color("SteelBlue", 0.38)
        ef_input_bottom();
    color("DarkOrange", 0.24)
        ef_input_upper();
}

else if (scene == "04_ef_result") {
    color("SteelBlue")
        ef_body();
}

else if (scene == "05_combined") {
    color("SteelBlue")
        combined_body();
}

else if (scene == "06_corner") {
    color("DarkOrange")
        intersection() {
            combined_body();
            corner_crop();
        }
}

else if (scene == "07_miter_inputs") {
    color("LightSlateGray", 0.16)
        intersection() {
            combined_body();
            corner_crop();
        }

    color("SteelBlue", 0.46)
        intersection() {
            right_front_miter_inputs(true);
            corner_crop();
        }
}

else {
    color("DarkOrange")
        intersection() {
            fixed_body();
            corner_crop();
        }
}
