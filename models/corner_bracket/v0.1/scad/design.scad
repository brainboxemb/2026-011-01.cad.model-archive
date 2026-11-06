// Interactive geometry walkthrough of the corner bracket.
// Select "design_step" in the OpenSCAD Customizer or pass -D on the CLI.
// Source geometry is shared with corner_bracket.scad; no second CAD model.
use <corner_bracket.scad>

design_step = "01_profile"; // [01_profile, 02_edge_chamfers, 03_nut_pockets, 04_print_relief, 05_access_plugs, 06_installed]

// Step 1: Extrude the rounded two-dimensional L profile to the bracket width.
if (design_step == "01_profile")
    color("SteelBlue")
        profile_extrusion();

// Step 2: Intersect the extrusion with the side-chamfer envelope.
else if (design_step == "02_edge_chamfers")
    color("SteelBlue") body();

// Step 3: Remove the captive-nut cavities, access windows and bolt holes.
else if (design_step == "03_nut_pockets")
    color("SteelBlue") difference() {
        body();
        nut_top();
        nut_side();
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
