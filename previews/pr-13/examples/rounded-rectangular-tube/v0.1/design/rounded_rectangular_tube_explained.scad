// Rounded rectangular tube — construction walkthrough.
//
// This file is deliberately separate from the printable example.
// It exposes the intermediate geometry used to create the two end chamfers
// and finishes with a comparison showing why the same global hull() idea
// becomes harder for a concave L-shaped bracket.

$fn = 64;

design_step = "09_convex_vs_concave"; // [01_profiles,02_outer_chamfer_inputs,03_outer_hull,04_hollow_tube,05_inner_chamfer_inputs,06_inner_chamfer_cut,07_bottom_chamfer_result,08_final,09_convex_vs_concave]

outer_width    = 30;
outer_depth    = 20;
length         = 60;
wall_thickness = 2.5;
outer_radius   = 5;

inner_chamfer = 0.6;
outer_chamfer = 0.4;
epsilon = 0.01;

inner_width  = outer_width - 2 * wall_thickness;
inner_depth  = outer_depth - 2 * wall_thickness;
inner_radius = max(outer_radius - wall_thickness, 0.01);

module rounded_rectangle(width, depth, radius) {
    hull()
        for (x = [radius, width - radius],
             y = [radius, depth - radius])
            translate([x, y])
                circle(radius);
}

module outer_2d()
    rounded_rectangle(outer_width, outer_depth, outer_radius);

module inner_2d()
    translate([wall_thickness, wall_thickness])
        rounded_rectangle(inner_width, inner_depth, inner_radius);

module thin_outer_profile(z, inset = 0, thickness = 0.08) {
    translate([0, 0, z])
        linear_extrude(thickness)
            offset(delta = inset)
                outer_2d();
}

module thin_inner_profile(z, expansion = 0, thickness = 0.08) {
    translate([0, 0, z])
        linear_extrude(thickness)
            offset(delta = expansion)
                inner_2d();
}

module outer_body() {
    hull() {
        translate([0, 0, 0])
            linear_extrude(epsilon)
                offset(delta = -outer_chamfer)
                    outer_2d();

        translate([0, 0, outer_chamfer])
            linear_extrude(length - 2 * outer_chamfer)
                outer_2d();

        translate([0, 0, length - epsilon])
            linear_extrude(epsilon)
                offset(delta = -outer_chamfer)
                    outer_2d();
    }
}

module continuous_inner_void(extra = 1) {
    translate([0, 0, -extra])
        linear_extrude(length + 2 * extra)
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

module hollow_tube_without_inner_chamfers() {
    difference() {
        outer_body();
        continuous_inner_void();
    }
}

module final_tube() {
    difference() {
        hollow_tube_without_inner_chamfers();

        inner_chamfer_cut();

        translate([0, 0, length])
            mirror([0, 0, 1])
                inner_chamfer_cut();
    }
}

// A deliberately simple concave L profile for the final comparison.
// This is not the full corner-bracket model; it isolates the hull() issue.
module l_profile_2d(size = 24, wall = 7) {
    union() {
        square([size, wall]);
        square([wall, size]);
    }
}

module l_layer(z, inset = 0, thickness = 0.08) {
    translate([0, 0, z])
        linear_extrude(thickness)
            offset(delta = inset)
                l_profile_2d();
}

module l_global_hull(height = 5, inset = -1.2) {
    hull() {
        l_layer(0, inset);
        l_layer(height, 0);
    }
}

module profiles_stage() {
    color([0.25, 0.55, 0.85])
        linear_extrude(1)
            outer_2d();

    color([1.0, 0.55, 0.15])
        translate([0, 0, 1.1])
            linear_extrude(1)
                inner_2d();
}

module outer_chamfer_inputs_stage() {
    // Close-up of the real 0.4 mm bottom chamfer.
    color([0.95, 0.45, 0.15])
        thin_outer_profile(0, -outer_chamfer, 0.06);

    color([0.20, 0.60, 0.90])
        thin_outer_profile(outer_chamfer, 0, 0.06);

    // A short continuation makes the relationship to the full tube obvious.
    color([0.70, 0.80, 0.90, 0.45])
        translate([0, 0, outer_chamfer])
            linear_extrude(5)
                outer_2d();
}

module outer_hull_stage() {
    // Only show the lower 8 mm so the 0.4 mm chamfer stays visible.
    intersection() {
        outer_body();
        translate([-2, -2, -0.2])
            cube([outer_width + 4, outer_depth + 4, 8]);
    }
}

module hollow_stage() {
    difference() {
        intersection() {
            outer_body();
            translate([-2, -2, -0.2])
                cube([outer_width + 4, outer_depth + 4, 12]);
        }
        continuous_inner_void();
    }
}

module inner_chamfer_inputs_stage() {
    // The orange opening is larger at the end face.
    color([0.95, 0.45, 0.15])
        thin_inner_profile(0, inner_chamfer, 0.06);

    // The blue opening is the normal hole 0.6 mm inside the tube.
    color([0.20, 0.60, 0.90])
        thin_inner_profile(inner_chamfer, 0, 0.06);

    // Ghost the surrounding tube so it is clear these are cutting profiles.
    %intersection() {
        hollow_tube_without_inner_chamfers();
        translate([-2, -2, -0.2])
            cube([outer_width + 4, outer_depth + 4, 7]);
    }
}

module inner_chamfer_cut_stage() {
    color([0.95, 0.35, 0.12])
        inner_chamfer_cut();

    %intersection() {
        hollow_tube_without_inner_chamfers();
        translate([-2, -2, -0.2])
            cube([outer_width + 4, outer_depth + 4, 7]);
    }
}

module bottom_chamfer_result_stage() {
    difference() {
        intersection() {
            hollow_tube_without_inner_chamfers();
            translate([-2, -2, -0.2])
                cube([outer_width + 4, outer_depth + 4, 8]);
        }
        inner_chamfer_cut();
    }
}

module convex_vs_concave_stage() {
    // LEFT: convex rounded rectangle. Hull can connect the two complete
    // profiles without inventing an unwanted bridge across an opening.
    translate([-42, 0, 0]) {
        color([0.20, 0.60, 0.90, 0.45])
            hull() {
                thin_outer_profile(0, -1.2);
                thin_outer_profile(5, 0);
            }

        color([0.95, 0.45, 0.15])
            thin_outer_profile(0, -1.2, 0.12);

        color([0.10, 0.35, 0.70])
            thin_outer_profile(5, 0, 0.12);
    }

    // RIGHT: concave L. hull() is convex by definition, so the result bridges
    // across the missing quadrant. That bridge is exactly why the bracket
    // needs extra clipping/subtractive logic instead of one global hull().
    translate([20, 0, 0]) {
        color([0.85, 0.25, 0.20, 0.40])
            l_global_hull();

        color([0.95, 0.45, 0.15])
            l_layer(0, -1.2, 0.12);

        color([0.10, 0.35, 0.70])
            l_layer(5, 0, 0.12);

        // Show the intended open quadrant as a reference void.
        %translate([7, 7, -0.5])
            cube([17, 17, 6]);
    }
}

if (design_step == "01_profiles")
    profiles_stage();
else if (design_step == "02_outer_chamfer_inputs")
    outer_chamfer_inputs_stage();
else if (design_step == "03_outer_hull")
    outer_hull_stage();
else if (design_step == "04_hollow_tube")
    hollow_stage();
else if (design_step == "05_inner_chamfer_inputs")
    inner_chamfer_inputs_stage();
else if (design_step == "06_inner_chamfer_cut")
    inner_chamfer_cut_stage();
else if (design_step == "07_bottom_chamfer_result")
    bottom_chamfer_result_stage();
else if (design_step == "08_final")
    final_tube();
else
    convex_vs_concave_stage();
