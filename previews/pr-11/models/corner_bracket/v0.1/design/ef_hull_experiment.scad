// Elephant-foot hull experiment for the Corner Bracket.
//
// Purpose:
//   Start with the COMPLETE bracket so the visible problem is clear first.
//   Only after that, zoom into one print side and one arm tip to show every
//   geometric step. The production model is not changed here.
//
// The experiment first shows the whole bracket with only the two main
// inside_relief_envelope() hulls, marks the four missing corner corrections,
// and shows the working bracket. It then shows the two real input surfaces
// of one EF hull and its local arm-tip defect,
// then constructs a strongest-possible "two surfaces only" candidate:
// take the exact removed-material cross-sections of the proven reference
// relief volume at the same two Y positions and hull those two sections.
//
// If that candidate still differs from the reference, the difference is
// caused by hull() convexification rather than by choosing the wrong simple
// offset for the two input surfaces.

use <../scad/corner_bracket.scad>

/* [Experiment] */
experiment_step = "A01_before_ef"; // [A01_before_ef, A02_surface_a, A03_surface_b, A04_both_surfaces, A05_main_hull, A06_main_result, A07_problem_locations, B01_before_ef, B02_surface_a, B03_surface_b, B04_both_surfaces, B05_main_hull, B06_corner_correction, B07_working_result, 00_whole_main_only, 00_whole_problem_points, 00_whole_working, 01_opening_profile, 02_inner_main_input, 03_outer_main_input, 04_both_main_inputs, 05_main_hull, 06_main_result, 07_missing_tip_volume, 08_reference_relief_volume, 09_reference_result, 10_exact_reference_inputs, 11_exact_two_surface_hull, 12_exact_candidate_result, 13_exact_candidate_xor, 14_exact_candidate_overcut, 15_exact_candidate_undercut]

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

// Only relief volume that can actually remove material from body() matters.
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

// Full working relief volume around this tip, before intersecting it with body().
// Keeping the relief volume itself (rather than the already-subtracted result)
// lets us take exact Y-plane cross-sections at the two hull positions.
module reference_tip_relief_volume() {
    intersection() {
        union() {
            main_positive_hull();
            positive_horizontal_tip_miter();
        }
        tip_crop();
    }
}

// Exact X/Z section of the working relief volume at world Y=y.
// After translate(), rotate(-90 around X) maps world Y to projection Z,
// while world Z becomes projection Y. projection(cut=true) therefore cuts
// the requested Y plane and returns a 2D X/Z profile.
module reference_section_2d(y) {
    projection(cut = true)
        rotate([-90, 0, 0])
            translate([0, -y, 0])
                reference_tip_relief_volume();
}

// Turn that exact 2D section back into the same kind of very thin 3D input
// surface used by the production elephant-foot hull.
module exact_reference_input(y) {
    translate([0, y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = eps, center = true)
                reference_section_2d(y);
}

// Strongest direct two-surface test:
// use the EXACT working-relief sections at the existing two Y positions,
// then ask one hull() to connect only those two surfaces.
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

module exact_candidate_undercut() {
    difference() {
        reference_effective_cut();
        exact_effective_cut();
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

// Complete printable bracket, but with ONLY the two main EF hulls.
// Nut pockets stay present so this is the real bracket shape, not a proxy.
module whole_main_only() {
    difference() {
        body();
        nut_top();
        nut_side();
        inside_relief_envelope();
    }
}

// Current working production geometry.
module whole_working() {
    difference() {
        body();
        nut_top();
        nut_side();
        inside_relief_envelope();
        relief_corner_miters();
    }
}

// These are exactly the small pieces of material that remain when only the
// two main hulls are used, but are removed by the working corner correction.
// On the whole bracket this reveals all four problematic arm-tip junctions.
module whole_missing_corner_material() {
    // Material that still exists in the main-only bracket and is touched by
    // the four local correction relief volumes. This is exactly what the corner
    // correction removes from the real bracket.
    intersection() {
        whole_main_only();
        relief_corner_miters();
    }
}

// Overview markers only. These are intentionally NOT relief geometry:
// their purpose is to make the four problem locations readable on the
// complete 40 mm bracket before the exact local geometry is shown.
module whole_problem_markers() {
    marker_r = 1.6;
    for (side = [-1, 1]) {
        // Horizontal arm: EF contact edge reaches the chamfered arm end.
        translate([armH - cs/2, side * (W/2 - cs/2), 0])
            sphere(r = marker_r, $fn = 24);

        // Vertical arm: equivalent junction at the lower arm end.
        translate([0, side * (W/2 - cs/2), -armV + cs/2])
            sphere(r = marker_r, $fn = 24);
    }
}

// Whole bracket BEFORE elephant-foot relief. Nut pockets stay present;
// only the EF relief volume has not yet been subtracted.
module whole_before_ef() {
    difference() {
        body();
        nut_top();
        nut_side();
    }
}

// Light whole-bracket context used behind the EF input surfaces.
// The colored geometry is the relief geometry; the grey bracket is only a
// positional reference so the reader can see exactly where Y=9.4/Y=10 sit.
module bracket_context() {
    color([0.72, 0.72, 0.72, 0.28])
        whole_before_ef();
}


// ---------- Whole-bracket walkthrough helpers ----------
// The whole bracket is kept in every image so all A/B stages have the same
// spatial reference and therefore a consistent camera/scale with --viewall.

module display_bounds() {
    translate([-t - 2, -W/2 - 2, -armV - 2])
        cube([armH + t + 4, W + 4, armV + t + 4]);
}

module display_surface_a() {
    intersection() {
        opening_layer(W/2 - ef);
        display_bounds();
    }
}

module display_surface_b() {
    intersection() {
        opening_layer(W/2, ef);
        display_bounds();
    }
}

module display_main_hull() {
    intersection() {
        main_positive_hull();
        display_bounds();
    }
}

// Show only the material-changing part of the four local correction volumes.
// This keeps the visual overlay inside the bracket outline and avoids changing
// the whole-bracket camera bounds.
module display_corner_correction() {
    intersection() {
        whole_main_only();
        relief_corner_miters();
    }
}

// Effective main EF relief volume over both print sides, clipped to the real body.
module display_main_relief_both_sides() {
    intersection() {
        whole_before_ef();
        inside_relief_envelope();
    }
}

// Combined working EF relief: main hulls plus the local corner correction.
module display_combined_relief() {
    intersection() {
        whole_before_ef();
        union() {
            inside_relief_envelope();
            relief_corner_miters();
        }
    }
}

module whole_context_solid() {
    color("SteelBlue") whole_before_ef();
}

module whole_context_ghost() {
    // Opaque light grey is deliberate: transparent OpenCSG previews produce
    // distracting striped artifacts that obscure the hull input surfaces.
    color([0.82, 0.82, 0.82]) whole_before_ef();
}

// -------- visual stages --------

// Sequence A — current main elephant-foot hulls WITHOUT the small corner correction.
// Every image keeps the complete bracket as the reference.
if (experiment_step == "A01_before_ef")
    whole_context_solid();

else if (experiment_step == "A02_surface_a") {
    whole_context_ghost();
    color("SteelBlue") display_surface_a();
}
else if (experiment_step == "A03_surface_b") {
    whole_context_ghost();
    color("DarkOrange") display_surface_b();
}
else if (experiment_step == "A04_both_surfaces") {
    whole_context_ghost();
    color("SteelBlue") display_surface_a();
    color("DarkOrange") display_surface_b();
}
else if (experiment_step == "A05_main_hull") {
    whole_context_ghost();
    color("DarkOrange", 0.82) display_main_hull();
}
else if (experiment_step == "A06_main_result")
    color("SteelBlue") whole_main_only();

else if (experiment_step == "A07_problem_locations") {
    color("SteelBlue") whole_main_only();
    color("Red") whole_problem_markers();
}

// Sequence B — repeat the same steps, then add the working corner correction.
else if (experiment_step == "B01_before_ef")
    whole_context_solid();

else if (experiment_step == "B02_surface_a") {
    whole_context_ghost();
    color("SteelBlue") display_surface_a();
}
else if (experiment_step == "B03_surface_b") {
    whole_context_ghost();
    color("DarkOrange") display_surface_b();
}
else if (experiment_step == "B04_both_surfaces") {
    whole_context_ghost();
    color("SteelBlue") display_surface_a();
    color("DarkOrange") display_surface_b();
}
else if (experiment_step == "B05_main_hull") {
    whole_context_ghost();
    color("DarkOrange", 0.82) display_main_hull();
}
else if (experiment_step == "B06_corner_correction") {
    // At whole-bracket scale, mark the four tiny correction locations.
    // The exact correction volume is shown later in the local C sequence.
    color("SteelBlue") whole_main_only();
    color("Red") whole_problem_markers();
}
else if (experiment_step == "B07_working_result")
    color("SteelBlue") whole_working();

// Existing overview/local experiment views retained below.
else if (experiment_step == "00_whole_main_only")
    color("SteelBlue") whole_main_only();

else if (experiment_step == "00_whole_problem_points") {
    color("SteelBlue") whole_main_only();
    color("Red") whole_problem_markers();
}
else if (experiment_step == "00_whole_working")
    color("SteelBlue") whole_working();

else if (experiment_step == "01_opening_profile") {
    bracket_context();
    // Show the source relief profile at the inner EF Y plane so its
    // relationship to the L-shaped bracket is immediately visible.
    color("SteelBlue")
        translate([0, W/2 - ef, 0])
            rotate([90, 0, 0])
                linear_extrude(height=0.08, center=true)
                    inside_opening_2d();
}
else if (experiment_step == "02_inner_main_input") {
    bracket_context();
    color("SteelBlue") opening_layer(W/2 - ef);
}
else if (experiment_step == "03_outer_main_input") {
    bracket_context();
    color("DarkOrange") opening_layer(W/2, ef);
}
else if (experiment_step == "04_both_main_inputs") {
    bracket_context();
    color("SteelBlue") opening_layer(W/2 - ef);
    color("DarkOrange") opening_layer(W/2, ef);
}
else if (experiment_step == "05_main_hull") {
    bracket_context();
    color("DarkOrange", 0.80) main_positive_hull();
}

else if (experiment_step == "06_main_result")
    color("SteelBlue") main_result();

else if (experiment_step == "07_missing_tip_volume")
    color("Red") missing_tip_volume();

else if (experiment_step == "08_reference_relief_volume") {
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

else if (experiment_step == "15_exact_candidate_undercut")
    color("Red") exact_candidate_undercut();
