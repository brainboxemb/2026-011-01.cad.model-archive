// Corner Bracket: generic cs + ef hull experiment.
//
// No print orientation is used here.
//
// Natural bracket coordinates:
//   X/Z = L profile
//   Y   = bracket width W
//
// First create the normal cs geometry.
// Then add ef generically across the same Y direction:
//
//   inner layer at Y = W/2 - ef : normal cs L at that Y
//   outer layer at Y = W/2      : same cs-aware L, additionally inset by ef
//
// hull() connects those two layers.
// The opposite side is simply the mirrored equivalent.
//
// STOP after the input layers until their geometry is visually correct.

/* [Illustration] */
junction_step = "00_cs_body"; // [00_cs_body, 01_inner_cs_L, 02_outer_ef_L, 03_both_inputs]

/* [Geometry] */
armH = 40;
armV = 40;
t = 10;
W = 20;
ce = 6;
c = 3;
cs = 2;
ef = 0.6;
r_in = 2.0;

/* [Hidden] */
$fn = 48;
display_thickness = 0.35;

// -----------------------------------------------------------------------------
// Base L: c / ce / inside radius, NO ef.
// -----------------------------------------------------------------------------

module inside_corner_2d(r) {
    difference() {
        translate([0, -r]) square([r, r]);
        translate([r, -r]) circle(r = r, $fn = 72);
    }
}

module clean_profile() {
    union() {
        polygon([
            [armH, 0],
            [armH, t - c],
            [armH - c, t],
            [-t + ce, t],
            [-t, t - ce],
            [-t, -armV + c],
            [-t + c, -armV],
            [0, -armV],
            [0, 0]
        ]);

        if (r_in > 0)
            inside_corner_2d(r_in);
    }
}

module outer_shape() {
    polygon([
        [armH, -armV],
        [armH, t - c],
        [armH - c, t],
        [-t + ce, t],
        [-t, t - ce],
        [-t, -armV + c],
        [-t + c, -armV]
    ]);
}

// -----------------------------------------------------------------------------
// Normal cs body.
// -----------------------------------------------------------------------------

module cs_envelope() {
    rotate([90, 0, 0])
        hull() {
            linear_extrude(height = W - 2 * cs, center = true)
                outer_shape();

            linear_extrude(height = W, center = true)
                offset(delta = -cs)
                    outer_shape();
        }
}

module cs_body() {
    intersection() {
        rotate([90, 0, 0])
            linear_extrude(height = W, center = true)
                clean_profile();

        cs_envelope();
    }
}

// -----------------------------------------------------------------------------
// Exact 2D cs cross-section at a Y position.
//
// For the 45-degree cs hull:
//   inset = cs - distance_from_outer_side
//
// At Y=W/2:
//   inset = cs
//
// At Y=W/2-ef:
//   inset = cs-ef
// -----------------------------------------------------------------------------

function cs_inset_at_y(y) =
    max(0, cs - (W/2 - y));

module cs_L_at_y(y) {
    intersection() {
        clean_profile();

        offset(delta = -cs_inset_at_y(y))
            outer_shape();
    }
}

// INPUT A: normal cs L, ef inward from the outer side.
module inner_cs_L_2d() {
    cs_L_at_y(W/2 - ef);
}

// INPUT B: first take the normal cs L on the outer side,
// then apply the generic ef inset to that complete L.
module outer_ef_L_2d() {
    offset(delta = -ef)
        cs_L_at_y(W/2);
}

// Thin X/Z layers only for visualizing the two hull inputs.
module layer_at_y(y, which = "inner", thickness = display_thickness) {
    translate([0, y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = thickness, center = true)
                if (which == "inner")
                    inner_cs_L_2d();
                else
                    outer_ef_L_2d();
}

// -----------------------------------------------------------------------------
// Scenes.
// Camera looks onto the complete L profile, with enough Y perspective to see
// that the two complete L layers are at different Y positions.
// -----------------------------------------------------------------------------

$vpr = [78, 0, 18];

if (junction_step == "00_cs_body") {
    color("SteelBlue")
        cs_body();
}

else if (junction_step == "01_inner_cs_L") {
    color("DarkOrange")
        layer_at_y(W/2 - ef, "inner");
}

else if (junction_step == "02_outer_ef_L") {
    color("DeepSkyBlue")
        layer_at_y(W/2, "outer");
}

else {
    color("DarkOrange", 0.55)
        layer_at_y(W/2 - ef, "inner");

    color("DeepSkyBlue", 0.72)
        layer_at_y(W/2, "outer");
}
