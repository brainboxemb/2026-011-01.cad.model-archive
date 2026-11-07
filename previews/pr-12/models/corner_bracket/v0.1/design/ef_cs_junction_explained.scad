// Corner Bracket: beam-style cs/ef experiment in PRINT coordinates.
//
// This file deliberately mirrors examples/hull_operations/v0.1/scad/
// hull_operations.scad as closely as possible.
//
// The important rule is: once we start the hull explanation, everything is
// already in print coordinates:
//
//   X/Y = footprint on the print bed
//   Z   = bracket width / print height
//
// So there is no rotation inside the ef construction.
//
// Construction:
//
//   1. Build a clean L profile with c / ce, but NO ef.
//   2. Build the normal cs envelope.
//   3. Intersect them -> cs_body().
//   4. Take the real bottom footprint of cs_body().
//   5. inset that footprint by ef -> ef_input_bottom().
//   6. take cs_body() from z=ef upward -> ef_input_upper().
//   7. hull the two inputs locally per arm so the concave L corner stays open.
//
// The production corner_bracket.scad is NOT changed by this experiment.

/* [Illustration] */
junction_step = "00_l_with_cs"; // [00_l_with_cs, 01_ef_inputs, 02_ef_hull, 03_result]

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
eps = 0.02;
display_thickness = 0.35;

// -----------------------------------------------------------------------------
// Base L footprint — equivalent to beam_profile_2d()
// -----------------------------------------------------------------------------

module inside_corner_2d(r) {
    difference() {
        translate([0, -r])
            square([r, r]);

        translate([r, -r])
            circle(r = r, $fn = 72);
    }
}

module l_profile_2d() {
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

// Convex outside helper used only for cs.
// Equivalent to the beam's cs_outline_2d().
module l_outer_2d() {
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

// Complete clean L prism in print coordinates.
// No ef is present anywhere.
module l_base() {
    linear_extrude(height = W)
        l_profile_2d();
}

// -----------------------------------------------------------------------------
// cs — same two-input hull idea as the beam
// -----------------------------------------------------------------------------

// INPUT 1:
// full outer footprint, but stopping cs before both print faces.
module cs_input_inner() {
    translate([0, 0, cs])
        linear_extrude(height = W - 2 * cs)
            l_outer_2d();
}

// INPUT 2:
// cs-inset outer footprint, extending over the complete print height.
module cs_input_outer() {
    linear_extrude(height = W)
        offset(delta = -cs)
            l_outer_2d();
}

module cs_hull() {
    hull() {
        cs_input_inner();
        cs_input_outer();
    }
}

// The real L intersected with the normal cs envelope.
module cs_body() {
    intersection() {
        l_base();
        cs_hull();
    }
}

// -----------------------------------------------------------------------------
// ef — literally the same construction order as the beam
// -----------------------------------------------------------------------------

// Actual footprint of the already-cs-chamfered L at the print bed.
module cs_bottom_footprint_2d() {
    projection()
        intersection() {
            cs_body();

            translate([-100, -100, -eps / 2])
                cube([200, 200, eps]);
        }
}

// INPUT 1:
// thin bottom plate derived from the real cs footprint, then inset by ef.
module ef_input_bottom(thickness = eps) {
    linear_extrude(height = thickness)
        offset(delta = -ef)
            cs_bottom_footprint_2d();
}

// INPUT 2:
// complete already-cs-chamfered L from ef above the print bed upward.
module ef_input_upper() {
    intersection() {
        cs_body();

        translate([-100, -100, ef])
            cube([200, 200, W + 20]);
    }
}

// -----------------------------------------------------------------------------
// Local arm hulls
//
// A single global hull between two concave L shapes would fill the inside
// corner. Therefore only the hull operation is split into the two arms.
// The two visible ef inputs above remain one L-shaped bottom plate and one
// complete upper L volume.
// -----------------------------------------------------------------------------

module horizontal_arm_mask_2d() {
    translate([-t - 2, -2])
        square([armH + t + 4, t + 4]);
}

module vertical_arm_mask_2d() {
    translate([-t - 2, -armV - 2])
        square([t + 4, armV + t + 4]);
}

module arm_mask_3d(which) {
    linear_extrude(height = W + 20)
        if (which == "horizontal")
            horizontal_arm_mask_2d();
        else
            vertical_arm_mask_2d();
}

module lower_arm_input(which) {
    intersection() {
        ef_input_bottom();
        arm_mask_3d(which);
    }
}

module upper_arm_input(which) {
    intersection() {
        ef_input_upper();
        arm_mask_3d(which);
    }
}

module arm_ef_hull(which) {
    hull() {
        lower_arm_input(which);
        upper_arm_input(which);
    }
}

module ef_hulls() {
    union() {
        arm_ef_hull("horizontal");
        arm_ef_hull("vertical");
    }
}

// The upper L is already part of both local hulls, but keeping it explicitly
// makes the intended construction obvious.
module result_body() {
    union() {
        ef_input_upper();
        ef_hulls();
    }
}

// -----------------------------------------------------------------------------
// Four scenes — same visual order as the beam
// -----------------------------------------------------------------------------

if (junction_step == "00_l_with_cs") {
    color("SteelBlue")
        cs_body();
}

else if (junction_step == "01_ef_inputs") {
    // BLUE: actual lower plate on the print bed.
    color("DeepSkyBlue", 0.62)
        ef_input_bottom(display_thickness);

    // ORANGE: complete already-cs-chamfered upper L.
    color("DarkOrange", 0.28)
        ef_input_upper();
}

else if (junction_step == "02_ef_hull") {
    color("SeaGreen")
        ef_hulls();
}

else {
    color("SeaGreen")
        result_body();
}
