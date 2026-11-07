// Beam experiment: build the elephant-foot hull FROM an already chamfered beam.
//
// The important construction order is:
//
//   1. Build the normal cs chamfer first.
//   2. Use that already-chamfered upper solid as one input to the ef hull.
//   3. Use an ef-inset bottom footprint as the other input.
//   4. hull() those two.
//
// This avoids feeding a square upper block into the ef hull.

/* [Demo] */
scene = "00_plain"; // [00_plain, 01_cs_inputs, 02_cs_result, 03_ef_inputs, 04_combined_result, 05_corner]

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

// ---------- cs hull ----------

// Extend below z=0 so cs changes the side/end edges but leaves the bottom
// contact perimeter available for the separate ef construction.
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

// cs INPUT 1: full outline, narrower across Y.
module cs_input_inner() {
    rotate([90, 0, 0])
        linear_extrude(height = width - 2 * cs, center = true)
            cs_outline_2d();
}

// cs INPUT 2: inset outline, full width across Y.
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

// ---------- ef hull built from the ALREADY chamfered body ----------

// INPUT 1 for ef:
//
// First take the actual bottom footprint of cs_body(). That footprint already
// contains the cs chamfers at the end/side junctions. Only AFTER that do we
// inset it by ef.
//
// So the lower ef plate is NOT a rectangular plate anymore: both ef inputs
// already carry the cs geometry.
module cs_bottom_footprint_2d() {
    projection()
        intersection() {
            cs_body();
            translate([-reach, -width, -eps / 2])
                cube([length + 2 * reach, width * 2, eps]);
        }
}

module ef_input_bottom() {
    linear_extrude(height = eps)
        offset(delta = -ef)
            cs_bottom_footprint_2d();
}

// INPUT 2 for ef:
// NOT a square block.
//
// Start from cs_body(), which already contains the side-face chamfer and the
// upper end chamfers, and keep only the solid from z=ef upward.
// This is the upper object fed to the ef hull.
module ef_input_upper_chamfered() {
    intersection() {
        cs_body();
        translate([-reach, -width, ef])
            cube([length + 2 * reach, width * 2, height + reach]);
    }
}

// The final construction is now one hull between TWO already-cs-chamfered
// inputs: the lower cs footprint inset by ef, and the upper cs body.
module combined_hull() {
    hull() {
        ef_input_bottom();
        ef_input_upper_chamfered();
    }
}

// Keep the result within the original real beam.
// No separate cs_hull/ef_hull intersection is used after this point.
module combined_body() {
    intersection() {
        beam();
        combined_hull();
    }
}

module corner_crop() {
    translate([length - cs - ef - 4, width / 2 - cs - ef - 4, -1])
        cube([cs + ef + 8, cs + ef + 8, cs + ef + 5]);
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
    // Blue: ef-inset bottom footprint.
    color("SteelBlue", 0.42)
        ef_input_bottom();

    // Orange: the ALREADY cs-chamfered upper solid.
    color("DarkOrange", 0.28)
        ef_input_upper_chamfered();
}

else if (scene == "04_combined_result") {
    color("SteelBlue")
        combined_body();
}

else {
    color("DarkOrange")
        intersection() {
            combined_body();
            corner_crop();
        }
}
