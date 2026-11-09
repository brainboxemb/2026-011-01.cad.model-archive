// Educational walkthrough of the corner bracket's edge treatments.
// Real geometry comes from ../scad/corner_bracket.scad; this is NOT a second model.

use <../scad/corner_bracket.scad>

/* [Illustration] */
chamfer_step = "01_plain_l"; // [01_plain_l,02_profile_chamfers,03_profile_body,04_outer_envelope,05_side_chamfer_inputs,06_side_chamfer_envelope,07_side_chamfered_body,08_continuous_side_relief,09_print_compensated_body,10_final]

/* [Hidden] */
// Defaults mirror the simplified v0.1 bracket.
horizontal_arm_length = 60;
vertical_arm_length = 60;
wall_thickness = 12;
arm_end_chamfer = 3;
outer_corner_chamfer = 6;
bracket_width = 24;
side_edge_chamfer = 2;
elephant_foot_relief = 0.6;
inside_corner_radius = 4;
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

else if (chamfer_step == "08_continuous_side_relief") {
    color("SteelBlue", 0.25)
        outer_side_chamfered_body();

    // Main red shape: one continuous cut per broad side.
    color("IndianRed", 0.85)
        render()
            intersection() {
            outer_side_chamfered_body();
            inside_side_relief_cuts();
        }

    // Orange: only the small arm-tip transition corrections.
    color("DarkOrange", 0.95)
        render()
            intersection() {
            outer_side_chamfered_body();
            arm_tip_relief_cuts();
        }
}

else if (chamfer_step == "09_print_compensated_body")
    color("SteelBlue")
        print_compensated_body();

else if (chamfer_step == "10_final")
    color("SteelBlue")
        bracket();
