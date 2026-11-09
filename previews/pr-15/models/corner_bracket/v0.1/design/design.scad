// Interactive geometry walkthrough of the simplified corner bracket.
// Select "design_step" in the OpenSCAD Customizer or pass -D on the CLI.
// Source geometry is shared with corner_bracket.scad; no second CAD model.

use <../scad/corner_bracket.scad>

design_step = "01_profile"; // [01_profile,02_outer_side_chamfers,03_side_relief,04_bolt_cuts,05_final,06_installed]

// Step 1: finished 2D L profile extruded to bracket width.
if (design_step == "01_profile")
    color("SteelBlue")
        profile_body();

// Step 2: apply the outer broad-side chamfer envelope.
else if (design_step == "02_outer_side_chamfers")
    color("SteelBlue")
        outer_side_chamfered_body();

// Step 3: remove one continuous elephant-foot relief per broad print side,
// plus only the two small arm-tip corrections.
else if (design_step == "03_side_relief") {
    color("SteelBlue", 0.35)
        outer_side_chamfered_body();

    color("IndianRed", 0.85)
        render()
            intersection() {
            outer_side_chamfered_body();
            inside_side_relief_cuts();
        }

    color("DarkOrange", 0.95)
        render()
            intersection() {
            outer_side_chamfered_body();
            arm_tip_relief_cuts();
        }
}

// Step 4: show the four countersunk M5 cutting volumes.
else if (design_step == "04_bolt_cuts") {
    color("SteelBlue", 0.35)
        print_compensated_body();

    color("IndianRed")
        bolt_cuts();
}

// Step 5: final printable bracket.
else if (design_step == "05_final")
    color("SteelBlue")
        bracket();

// Step 6: installed preview with plywood and hardware ghosts.
else if (design_step == "06_installed") {
    color("SteelBlue")
        bracket();

    %wood();
    %color("Silver")
        hardware();
}
