// Interactive geometry walkthrough of the corner bracket.
// Select "design_step" in the OpenSCAD Customizer or pass -D on the CLI.
// Source geometry is shared with corner_bracket.scad; no second CAD model.
use <../scad/corner_bracket.scad>

design_step = "01_profile"; // [01_profile, 02_outer_side_chamfers, 03_fastener_cuts, 04_print_relief, 05_access_plugs, 06_installed]

// Step 1: Extrude the rounded two-dimensional L profile to the bracket width.
if (design_step == "01_profile")
    color("SteelBlue")
        profile_body();

// Step 2: Clip the profile body with the outer side-chamfer keep envelope.
else if (design_step == "02_outer_side_chamfers")
    color("SteelBlue") outer_side_chamfered_body();

// Step 3: Subtract the captive-nut, access-window and bolt cutting volumes.
else if (design_step == "03_fastener_cuts")
    color("SteelBlue") difference() {
        outer_side_chamfered_body();
        top_fastener_cut();
        vertical_fastener_cut();
    }

// Step 4: Apply elephant-foot relief around wood-facing edges.
else if (design_step == "04_print_relief")
    color("SteelBlue") bracket();

// Step 5: Show the two removable access plugs in printing orientation.
else if (design_step == "05_access_plugs")
    color("Orange") plugs_print_pair();

// Step 6: Show the assembled joint with translucent plywood and installed plugs.
else if (design_step == "06_installed") {
    color("SteelBlue") bracket();
    color("Orange") plugs_in_place();
    %wood();
}
