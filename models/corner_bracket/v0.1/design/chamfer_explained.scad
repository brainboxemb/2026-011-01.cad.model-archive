// Educational illustration: three different chamfer operations on Corner Bracket.
// Real geometry comes from ../scad/corner_bracket.scad; this is NOT a second model.
// In OpenSCAD Customizer select chamfer_step to inspect each transformation.
use <../scad/corner_bracket.scad>

/* [Illustration] */
chamfer_step = "01_sharp_profile"; // [01_sharp_profile, 02_profile_chamfers, 03_extruded_profile, 04_convex_outline, 05_hull_inputs, 06_hull_envelope, 07_intersection, 08_print_relief, 09_final]
/* [Hidden] */
// Initial sharp profile is only a reference, not a printable production part.
// Defaults correspond to corner_bracket.scad v0.1.
armH = 40;
armV = 40;
t = 10;
c = 3;
ce = 6;
W = 20;
cs = 2;
$fn = 48;

module initial_sharp_outline() {
    polygon([
        [armH,0], [armH,t], [-t,t], [-t,-armV], [0,-armV], [0,0]
    ]);
}

// Place translucent 3D layers side by side in the same geometry space.
// Orange: full-width but inset outside outline. Blue: full outline, inner 16 mm.
module show_hull_inputs() {
    rotate([90,0,0]) {
        color("SteelBlue", 0.7)
            linear_extrude(height=W-2*cs, center=true)
                outer_shape();
        color("DarkOrange", 0.45)
            linear_extrude(height=W, center=true)
                offset(delta=-cs) outer_shape();
    }
}

if (chamfer_step == "01_sharp_profile")
    color("SteelBlue")
        rotate([90,0,0]) linear_extrude(height=0.6) initial_sharp_outline();

else if (chamfer_step == "02_profile_chamfers")
    color("SteelBlue")
        rotate([90,0,0]) linear_extrude(height=0.6) profile();

else if (chamfer_step == "03_extruded_profile")
    color("SteelBlue") profile_extrusion();

else if (chamfer_step == "04_convex_outline")
    color("DarkOrange")
        rotate([90,0,0]) linear_extrude(height=0.6) outer_shape();

else if (chamfer_step == "05_hull_inputs")
    show_hull_inputs();

else if (chamfer_step == "06_hull_envelope")
    color("DarkOrange", 0.75) side_chamfer_env();

else if (chamfer_step == "07_intersection")
    color("SteelBlue") body();

else if (chamfer_step == "08_print_relief") {
    color("SteelBlue") body();
    translate([armH+16,0,0]) color("DarkOrange")
        chamfered_body();
}
else if (chamfer_step == "09_final")
    color("SteelBlue") bracket();
