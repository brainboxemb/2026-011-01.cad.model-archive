// Educational walkthrough of the corner bracket's three edge treatments.
// Real geometry comes from ../scad/corner_bracket.scad; this is NOT a second model.
// Select chamfer_step in the OpenSCAD Customizer.

use <../scad/corner_bracket.scad>

/* [Illustration] */
chamfer_step = "01_plain_l"; // [01_plain_l,02_profile_chamfers,03_profile_body,04_outer_envelope,05_side_chamfer_inputs,06_side_chamfer_envelope,07_side_chamfered_body,08_elephant_foot_cuts,09_print_compensated_body,10_final]

/* [Hidden] */
// Defaults mirror corner_bracket.scad v0.1.
horizontal_arm_length = 40;
vertical_arm_length = 40;
wall_thickness = 10;
arm_end_chamfer = 3;
outer_corner_chamfer = 6;
bracket_width = 20;
side_edge_chamfer = 2;
elephant_foot_relief = 0.6;
inside_corner_radius = 2;
$fn = 48;

module plain_l_profile_2d() {
    polygon([
        [horizontal_arm_length, 0],
        [horizontal_arm_length, wall_thickness],
        [-wall_thickness, wall_thickness],
        [-wall_thickness, -vertical_arm_length],
        [0, -vertical_arm_length],
        [0, 0]
    ]);
}

module show_side_chamfer_inputs() {
    rotate([90, 0, 0]) {
        color("SteelBlue", 0.75)
            linear_extrude(
                height = bracket_width - 2 * side_edge_chamfer,
                center = true
            )
                outer_chamfer_envelope_2d();

        color("DarkOrange", 0.5)
            linear_extrude(height = bracket_width, center = true)
                offset(delta = -side_edge_chamfer)
                    outer_chamfer_envelope_2d();
    }
}

if (chamfer_step == "01_plain_l")
    color("SteelBlue")
        rotate([90, 0, 0])
            linear_extrude(height = 0.6)
                plain_l_profile_2d();

else if (chamfer_step == "02_profile_chamfers")
    color("SteelBlue")
        rotate([90, 0, 0])
            linear_extrude(height = 0.6)
                bracket_profile_2d();

else if (chamfer_step == "03_profile_body")
    color("SteelBlue")
        profile_body();

else if (chamfer_step == "04_outer_envelope")
    color("DarkOrange")
        rotate([90, 0, 0])
            linear_extrude(height = 0.6)
                outer_chamfer_envelope_2d();

else if (chamfer_step == "05_side_chamfer_inputs")
    show_side_chamfer_inputs();

else if (chamfer_step == "06_side_chamfer_envelope")
    color("DarkOrange", 0.8)
        outer_side_chamfer_keep_envelope();

else if (chamfer_step == "07_side_chamfered_body")
    color("SteelBlue")
        outer_side_chamfered_body();

else if (chamfer_step == "08_elephant_foot_cuts") {
    color("SteelBlue", 0.35)
        outer_side_chamfered_body();
    color("IndianRed")
        elephant_foot_relief_cuts();
}

else if (chamfer_step == "09_print_compensated_body")
    color("SteelBlue")
        print_compensated_body();

else if (chamfer_step == "10_final")
    color("SteelBlue")
        bracket();
