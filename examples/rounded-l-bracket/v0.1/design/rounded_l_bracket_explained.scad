// Rounded L bracket — construction walkthrough.
//
// Standalone teaching file for the rounded L bracket example.
// It exposes the deliberately extended convex profiles, both chamfer
// constructions, and the final trimming operation.

$fn = 64;

design_step = "10_chamfer_closeup"; // [01_outer_profile,02_inner_profile,03_shell_profile,04_outer_chamfer_inputs,05_outer_body,06_inner_chamfer_inputs,07_inner_chamfer_cut,08_before_trim,09_final_trim,10_chamfer_closeup]

leg_x          = 40;
leg_y          = 30;
height         = 20;
wall_thickness = 2.5;
outer_radius   = 5;
inner_chamfer  = 0.6;
outer_chamfer  = 0.4;

epsilon      = 0.01;
inner_radius = max(outer_radius - wall_thickness, 0.01);

profile_x = leg_x + 2;
profile_y = leg_y + 2;

// ---------- Shared geometry ----------

module outer_2d() {
    hull() {
        translate([outer_radius, outer_radius])
            circle(outer_radius);

        translate([profile_x - epsilon, 0])
            square([epsilon, profile_y]);

        translate([0, profile_y - epsilon])
            square([profile_x, epsilon]);
    }
}

module inner_2d() {
    translate([wall_thickness, wall_thickness])
        hull() {
            translate([inner_radius, inner_radius])
                circle(inner_radius);

            translate([profile_x - epsilon, 0])
                square([epsilon, profile_y]);

            translate([0, profile_y - epsilon])
                square([profile_x, epsilon]);
        }
}

module shell_2d() {
    difference() {
        outer_2d();
        inner_2d();
    }
}

module outer_end_layer(z, inset = 0, thickness = 0.08) {
    translate([0, 0, z])
        linear_extrude(thickness)
            offset(r = inset)
                outer_2d();
}

module inner_end_layer(z, expansion = 0, thickness = 0.08) {
    translate([0, 0, z])
        linear_extrude(thickness)
            offset(r = expansion)
                inner_2d();
}

module outer_body() {
    hull() {
        linear_extrude(epsilon)
            offset(r = -outer_chamfer)
                outer_2d();

        translate([0, 0, outer_chamfer])
            linear_extrude(height - 2 * outer_chamfer)
                outer_2d();

        translate([0, 0, height - epsilon])
            linear_extrude(epsilon)
                offset(r = -outer_chamfer)
                    outer_2d();
    }
}

module continuous_inner_cutout(extra = 1) {
    translate([0, 0, -extra])
        linear_extrude(height + 2 * extra)
            inner_2d();
}

module inner_chamfer_cut() {
    hull() {
        translate([0, 0, -epsilon])
            linear_extrude(2 * epsilon)
                offset(r = inner_chamfer)
                    inner_2d();

        translate([0, 0, inner_chamfer])
            linear_extrude(epsilon)
                inner_2d();
    }
}

module before_trim() {
    difference() {
        outer_body();
        continuous_inner_cutout();
        inner_chamfer_cut();

        translate([0, 0, height])
            mirror([0, 0, 1])
                inner_chamfer_cut();
    }
}

module trim_box(extra = 1) {
    translate([0, 0, -extra])
        cube([leg_x, leg_y, height + 2 * extra]);
}

module final_bracket() {
    intersection() {
        before_trim();
        trim_box();
    }
}

// ---------- Walkthrough stages ----------

module stage_01_outer_profile() {
    color([0.20, 0.55, 0.85])
        linear_extrude(0.6)
            outer_2d();

    // Mark the final X/Y leg limits. The profile extends beyond both.
    %translate([0, 0, -0.1])
        cube([leg_x, leg_y, 0.8]);
}

module stage_02_inner_profile() {
    color([0.95, 0.50, 0.15])
        linear_extrude(0.6)
            inner_2d();

    %translate([0, 0, -0.1])
        cube([leg_x, leg_y, 0.8]);
}

module stage_03_shell_profile() {
    color([0.25, 0.65, 0.45])
        linear_extrude(0.8)
            shell_2d();

    %translate([0, 0, -0.1])
        cube([leg_x, leg_y, 1.0]);
}

module stage_04_outer_chamfer_inputs() {
    color([0.95, 0.45, 0.15])
        outer_end_layer(0, -outer_chamfer);

    color([0.20, 0.55, 0.85])
        outer_end_layer(outer_chamfer, 0);

    %translate([0, 0, outer_chamfer])
        linear_extrude(5)
            outer_2d();
}

module stage_05_outer_body() {
    intersection() {
        outer_body();

        translate([-2, -2, -0.2])
            cube([profile_x + 4, profile_y + 4, 8]);
    }
}

module stage_06_inner_chamfer_inputs() {
    color([0.95, 0.45, 0.15])
        inner_end_layer(0, inner_chamfer);

    color([0.20, 0.55, 0.85])
        inner_end_layer(inner_chamfer, 0);

    %difference() {
        intersection() {
            outer_body();
            translate([-2, -2, -0.2])
                cube([profile_x + 4, profile_y + 4, 7]);
        }
        continuous_inner_cutout();
    }
}

module stage_07_inner_chamfer_cut() {
    color([0.95, 0.35, 0.12])
        inner_chamfer_cut();

    %difference() {
        intersection() {
            outer_body();
            translate([-2, -2, -0.2])
                cube([profile_x + 4, profile_y + 4, 7]);
        }
        continuous_inner_cutout();
    }
}

module stage_08_before_trim() {
    before_trim();

    // Ghost the final trim box to show the deliberate overhang.
    %trim_box();
}

module stage_09_final_trim() {
    final_bracket();
}

module stage_10_chamfer_closeup() {
    // Keep the rounded corner and only the lower 8 mm.
    intersection() {
        final_bracket();

        translate([-1, -1, -0.2])
            cube([
                min(18, leg_x + 1),
                min(18, leg_y + 1),
                8
            ]);
    }
}

// ---------- Selector ----------

if (design_step == "01_outer_profile")
    stage_01_outer_profile();
else if (design_step == "02_inner_profile")
    stage_02_inner_profile();
else if (design_step == "03_shell_profile")
    stage_03_shell_profile();
else if (design_step == "04_outer_chamfer_inputs")
    stage_04_outer_chamfer_inputs();
else if (design_step == "05_outer_body")
    stage_05_outer_body();
else if (design_step == "06_inner_chamfer_inputs")
    stage_06_inner_chamfer_inputs();
else if (design_step == "07_inner_chamfer_cut")
    stage_07_inner_chamfer_cut();
else if (design_step == "08_before_trim")
    stage_08_before_trim();
else if (design_step == "09_final_trim")
    stage_09_final_trim();
else
    stage_10_chamfer_closeup();
