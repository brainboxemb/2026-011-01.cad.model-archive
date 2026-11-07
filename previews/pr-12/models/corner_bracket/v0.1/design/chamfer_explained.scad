// Educational illustration: Corner Bracket chamfers and elephant-foot relief.
//
// IMPORTANT:
// This file does not invent a second bracket implementation.
// It calls the actual production modules from ../scad/corner_bracket.scad and
// only exposes them in smaller, easier-to-understand stages.
//
// In OpenSCAD Customizer select chamfer_step and walk through the stages in
// order.  The aim is:
//   first see the geometry,
//   then see the helper object,
//   then see what that helper changes.
//
// Real printable geometry stays in ../scad/corner_bracket.scad.

use <../scad/corner_bracket.scad>

/* [Illustration] */
chamfer_step = "01_sharp_profile"; // [01_sharp_profile, 02_profile_chamfers, 03_extruded_profile, 04_convex_outline, 05_cs_hull_inputs, 06_cs_hull_envelope, 07_cs_body, 08_inside_opening, 09_ef_layer_inputs, 10_ef_one_side, 11_ef_both_sides, 12_before_end_correction, 13_end_correction, 14_final_relief, 15_final_bracket]

/* [Hidden] */
// Defaults mirror corner_bracket.scad v0.1.
armH = 40;
armV = 40;
t = 10;
c = 3;
ce = 6;
W = 20;
cs = 2;
ef = 0.6;
r_in = 2.0;
$fn = 48;

// -----------------------------------------------------------------------------
// 2D starting point.
// -----------------------------------------------------------------------------

module initial_sharp_outline() {
    polygon([
        [armH,0],
        [armH,t],
        [-t,t],
        [-t,-armV],
        [0,-armV],
        [0,0]
    ]);
}

// -----------------------------------------------------------------------------
// cs explanation.
// -----------------------------------------------------------------------------

module show_cs_hull_inputs() {
    rotate([90,0,0]) {
        // Blue: full outside outline, but narrower over Y.
        color("SteelBlue", 0.70)
            linear_extrude(height=W-2*cs, center=true)
                outer_shape();

        // Orange: inset outside outline, but full W over Y.
        color("DarkOrange", 0.45)
            linear_extrude(height=W, center=true)
                offset(delta=-cs)
                    outer_shape();
    }
}

// -----------------------------------------------------------------------------
// ef explanation.
//
// The real production construction is:
//   opening_layer(side*(W/2-ef), 0)
//   opening_layer(side*W/2, ef)
//   hull() between those two layers.
//
// These helpers only make that existing operation visible.
// -----------------------------------------------------------------------------

module one_side_ef_relief(side=1) {
    hull() {
        opening_layer(side * (W / 2 - ef));
        opening_layer(side * W / 2, ef);
    }
}

// Only the part of the relief cutter that actually overlaps the bracket.
// This makes it much easier to understand what material will disappear.
module one_side_removed_material(side=1) {
    intersection() {
        body();
        one_side_ef_relief(side);
    }
}

module both_sides_removed_material() {
    intersection() {
        body();
        inside_relief_envelope();
    }
}

// Body after the main continuous ef relief, but BEFORE the small arm-end
// correction where ef meets the diagonal cs edge.
module before_end_correction() {
    difference() {
        body();
        inside_relief_envelope();
    }
}

// -----------------------------------------------------------------------------
// Small arm-tip junction close-up.
//
// Left   = main ef relief only.
// Middle = tiny extra cutter only.
// Right  = final production relief.
// -----------------------------------------------------------------------------

module tip_junction_crop() {
    translate([armH-cs-ef-3, W/2-cs-ef-3, -1.5])
        cube([cs+ef+6, cs+ef+6, ef+5]);
}

module show_end_correction_triplet() {
    translate([-20-armH+2, -W/2+2, 0])
        color("SteelBlue")
            intersection() {
                before_end_correction();
                tip_junction_crop();
            }

    translate([-armH+2, -W/2+2, 0])
        color("IndianRed")
            intersection() {
                relief_corner_miters();
                tip_junction_crop();
            }

    translate([20-armH+2, -W/2+2, 0])
        color("DarkOrange")
            intersection() {
                chamfered_body();
                tip_junction_crop();
            }
}

// -----------------------------------------------------------------------------
// Stages.
// -----------------------------------------------------------------------------

if (chamfer_step == "01_sharp_profile") {
    color("SteelBlue")
        rotate([90,0,0])
            linear_extrude(height=0.6)
                initial_sharp_outline();
}

else if (chamfer_step == "02_profile_chamfers") {
    color("SteelBlue")
        rotate([90,0,0])
            linear_extrude(height=0.6)
                profile();
}

else if (chamfer_step == "03_extruded_profile") {
    color("SteelBlue")
        profile_extrusion();
}

else if (chamfer_step == "04_convex_outline") {
    color("DarkOrange")
        rotate([90,0,0])
            linear_extrude(height=0.6)
                outer_shape();
}

else if (chamfer_step == "05_cs_hull_inputs") {
    show_cs_hull_inputs();
}

else if (chamfer_step == "06_cs_hull_envelope") {
    color("DarkOrange", 0.75)
        side_chamfer_env();
}

else if (chamfer_step == "07_cs_body") {
    color("SteelBlue")
        body();
}

else if (chamfer_step == "08_inside_opening") {
    // Thin 3D display of the 2D opening whose boundary follows:
    // horizontal inside face -> r_in arc -> vertical inside face.
    color("DeepSkyBlue", 0.85)
        rotate([90,0,0])
            linear_extrude(height=0.6, center=true)
                inside_opening_2d();
}

else if (chamfer_step == "09_ef_layer_inputs") {
    // Show only one Y side first.  The opposite side is identical.
    color("SteelBlue", 0.75)
        opening_layer(W/2-ef);

    color("DarkOrange", 0.55)
        opening_layer(W/2, ef);
}

else if (chamfer_step == "10_ef_one_side") {
    // Show only the material of the bracket that this one-side hull removes.
    color("SeaGreen", 0.90)
        one_side_removed_material(1);

    color("LightGray", 0.16)
        body();
}

else if (chamfer_step == "11_ef_both_sides") {
    // Same operation repeated at Y=-W/2.
    color("SeaGreen", 0.90)
        both_sides_removed_material();

    color("LightGray", 0.16)
        body();
}

else if (chamfer_step == "12_before_end_correction") {
    // Main ef relief is already complete here.
    // Only the small meeting point with cs at the arm tips remains.
    color("SteelBlue")
        before_end_correction();
}

else if (chamfer_step == "13_end_correction") {
    show_end_correction_triplet();
}

else if (chamfer_step == "14_final_relief") {
    color("SteelBlue")
        chamfered_body();
}

else {
    color("SteelBlue")
        bracket();
}
