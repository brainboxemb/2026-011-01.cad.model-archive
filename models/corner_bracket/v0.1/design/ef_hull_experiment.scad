// Elephant-foot hull experiment for the Corner Bracket.
//
// Purpose:
//   Show EVERY geometric step for one print side and one arm tip.
//   The production model is not changed here.
//
// The experiment starts with the two real input surfaces of
// inside_relief_envelope(), shows their hull and its visible tip defect,
// then constructs a strongest-possible "two surfaces only" candidate:
// take the exact removed-material cross-sections of the proven reference
// cutter at the same two Y positions and hull those two sections.
//
// If that candidate still differs from the reference, the difference is
// caused by hull() convexification rather than by choosing the wrong simple
// offset for the two input surfaces.

use <../scad/corner_bracket.scad>

/* [Experiment] */
experiment_step = "04_both_main_inputs"; // [01_opening_profile, 02_inner_main_input, 03_outer_main_input, 04_both_main_inputs, 05_main_hull, 06_main_result, 07_missing_tip_volume, 08_reference_cutter, 09_reference_result, 10_exact_reference_inputs, 11_exact_two_surface_hull, 12_exact_candidate_result, 13_exact_candidate_xor, 14_exact_candidate_overcut]

/* [Hidden] */
// Keep aligned with production defaults.
W = 20;
armH = 40;
armV = 40;
t = 10;
c = 3;
ce = 6;
cs = 2;
ef = 0.6;
r_in = 2;
$fn = 48;

eps = 0.002;
section_thickness = 0.02;

// Local crop around the horizontal arm end at the +Y print side.
// All actual operations are performed on the full model first; this box
// only makes the rendered explanation readable.
module tip_crop() {
    translate([armH - cs - ef - 4,
               W/2 - cs - ef - 2,
               -2.5])
        cube([cs + ef + 7,
              cs + ef + 4,
              5]);
}

module crop() {
    intersection() {
        children();
        tip_crop();
    }
}

// One of the TWO production elephant-foot hulls: +Y print side only.
module main_positive_hull() {
    hull() {
        opening_layer(W/2 - ef);
        opening_layer(W/2, ef);
    }
}

// The corresponding proven local correction at the horizontal arm tip.
// This is copied from the production parameterization, but only for +Y.
module positive_horizontal_tip_miter() {
    s2 = sqrt(2) / 2;
    relief_miter_hull([armH - cs - s2, W/2 + s2, 0],
                      [s2, s2, 0], [0, 0, 1], [s2, -s2, 0],
                      cs * sqrt(2) + 2);
}

// Only cutting volume that can actually remove material from body() matters.
module main_effective_cut() {
    intersection() {
        body();
        main_positive_hull();
        tip_crop();
    }
}

module reference_effective_cut() {
    intersection() {
        body();
        union() {
            main_positive_hull();
            positive_horizontal_tip_miter();
        }
        tip_crop();
    }
}

module missing_tip_volume() {
    difference() {
        reference_effective_cut();
        main_effective_cut();
    }
}

// Thin slab centred on a Y location. It turns the exact effective reference
// cutter into a real 3D input surface for a new hull() experiment.
module y_slab(y, thickness = section_thickness) {
    translate([-100, y - thickness/2, -100])
        cube([200, thickness, 200]);
}

module exact_reference_input(y) {
    intersection() {
        reference_effective_cut();
        y_slab(y);
    }
}

// This is deliberately the strongest possible version of the user's idea:
// do not guess the tip shape. Use the EXACT cross-sections of the working
// cutter at the same two Y positions, then ask one hull() to connect them.
module exact_two_surface_hull() {
    hull() {
        exact_reference_input(W/2 - ef);
        exact_reference_input(W/2);
    }
}

module exact_effective_cut() {
    intersection() {
        body();
        exact_two_surface_hull();
        tip_crop();
    }
}

module exact_candidate_xor() {
    union() {
        difference() {
            reference_effective_cut();
            exact_effective_cut();
        }
        difference() {
            exact_effective_cut();
            reference_effective_cut();
        }
    }
}

module exact_candidate_overcut() {
    difference() {
        exact_effective_cut();
        reference_effective_cut();
    }
}

module main_result() {
    crop()
        difference() {
            body();
            main_positive_hull();
        }
}

module reference_result() {
    crop()
        difference() {
            body();
            union() {
                main_positive_hull();
                positive_horizontal_tip_miter();
            }
        }
}

module exact_candidate_result() {
    crop()
        difference() {
            body();
            exact_two_surface_hull();
        }
}

// -------- visual stages --------

if (experiment_step == "01_opening_profile") {
    // 2D source profile shown as a thin plate for a consistent 3D camera.
    crop()
        color("SteelBlue")
            translate([0, W/2 - ef, 0])
                rotate([90, 0, 0])
                    linear_extrude(height=0.08, center=true)
                        inside_opening_2d();
}
else if (experiment_step == "02_inner_main_input")
    crop() color("SteelBlue") opening_layer(W/2 - ef);

else if (experiment_step == "03_outer_main_input")
    crop() color("DarkOrange") opening_layer(W/2, ef);

else if (experiment_step == "04_both_main_inputs") {
    crop() color("SteelBlue") opening_layer(W/2 - ef);
    crop() color("DarkOrange") opening_layer(W/2, ef);
}
else if (experiment_step == "05_main_hull")
    crop() color("DarkOrange", 0.85) main_positive_hull();

else if (experiment_step == "06_main_result")
    color("SteelBlue") main_result();

else if (experiment_step == "07_missing_tip_volume")
    color("Red") missing_tip_volume();

else if (experiment_step == "08_reference_cutter") {
    color("DarkOrange", 0.75) main_effective_cut();
    color("Red", 0.95) missing_tip_volume();
}
else if (experiment_step == "09_reference_result")
    color("SteelBlue") reference_result();

else if (experiment_step == "10_exact_reference_inputs") {
    color("SteelBlue") exact_reference_input(W/2 - ef);
    color("DarkOrange") exact_reference_input(W/2);
}
else if (experiment_step == "11_exact_two_surface_hull")
    color("DarkOrange", 0.85) exact_effective_cut();

else if (experiment_step == "12_exact_candidate_result")
    color("SteelBlue") exact_candidate_result();

else if (experiment_step == "13_exact_candidate_xor")
    color("Red") exact_candidate_xor();

else if (experiment_step == "14_exact_candidate_overcut")
    color("Red") exact_candidate_overcut();
