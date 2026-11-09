// Rounded rectangular tube — construction walkthrough.
//
// Standalone teaching file for the rounded rectangular tube example.
// It exposes each construction step used for the outside and inside
// end chamfers. It is not the printable source file.

$fn = 64;

design_step = "09_chamfer_closeup"; // [01_profiles,02_outer_chamfer_inputs,03_outer_hull,04_hollow_tube,05_inner_chamfer_inputs,06_inner_chamfer_cut,07_bottom_chamfer_result,08_final,09_chamfer_closeup]

outer_width     = 30;
outer_depth     = 20;
length          = 60;
wall_thickness  = 2.5;
outer_radius    = 5;

inner_chamfer   = 0.6;
outer_chamfer   = 0.4;
epsilon         = 0.01;

inner_width  = outer_width - 2 * wall_thickness;
inner_depth  = outer_depth - 2 * wall_thickness;
inner_radius = max(outer_radius - wall_thickness, 0.01);

// ---------- Shared geometry ----------

module rounded_rectangle(width, depth, radius) {
    hull()
        for (x = [radius, width - radius],
             y = [radius, depth - radius])
            translate([x, y])
                circle(radius);
}

module outer_2d() {
    rounded_rectangle(outer_width, outer_depth, outer_radius);
}

module inner_2d() {
    translate([wall_thickness, wall_thickness])
        rounded_rectangle(inner_width, inner_depth, inner_radius);
}

module outer_end_layer(z, inset = 0, thickness = 0.06) {
    translate([0, 0, z])
        linear_extrude(thickness)
            offset(delta = inset)
                outer_2d();
}

module inner_end_layer(z, expansion = 0, thickness = 0.06) {
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

// ---------- Walkthrough stages ----------

module stage_01_profiles() {
    // The profiles are shown as thin solids so both are visible in 3D.
    color([0.20, 0.55, 0.85])
        linear_extrude(0.6)
            outer_2d();

    color([0.95, 0.50, 0.15])
        translate([0, 0, 0.8])
            linear_extrude(0.6)
                inner_2d();
}

module stage_02_outer_chamfer_inputs() {
    // Orange: smaller end-face profile.
    color([0.95, 0.45, 0.15])
        outer_end_layer(0, -outer_chamfer, 0.08);

    // Blue: normal outer profile, only 0.4 mm farther inside.
    color([0.20, 0.55, 0.85])
        outer_end_layer(outer_chamfer, 0, 0.08);

    // Ghost a short normal continuation to show which profile continues.
    %translate([0, 0, outer_chamfer])
        linear_extrude(5)
            outer_2d();
}

module stage_03_outer_hull() {
    // Show only the lower 8 mm so the small outside chamfer stays visible.
    intersection() {
        outer_body();

        translate([-2, -2, -0.2])
            cube([outer_width + 4, outer_depth + 4, 8]);
    }
}

module stage_04_hollow_tube() {
    // Same lower section, now with the normal through-hole removed.
    intersection() {
        hollow_tube_without_inner_chamfers();

        translate([-2, -2, -0.2])
            cube([outer_width + 4, outer_depth + 4, 10]);
    }
}

module stage_05_inner_chamfer_inputs() {
    // Orange: enlarged opening at the end face.
    color([0.95, 0.45, 0.15])
        inner_end_layer(0, inner_chamfer, 0.08);

    // Blue: normal opening 0.6 mm farther into the tube.
    color([0.20, 0.55, 0.85])
        inner_end_layer(inner_chamfer, 0, 0.08);

    // Ghost the lower tube section for context.
    %intersection() {
        hollow_tube_without_inner_chamfers();

        translate([-2, -2, -0.2])
            cube([outer_width + 4, outer_depth + 4, 7]);
    }
}

module stage_06_inner_chamfer_cut() {
    // The hull is a solid tapered cutter. Much of it is already inside the
    // normal hollow opening; only its outer rim overlaps the tube wall.
    color([0.95, 0.35, 0.12])
        inner_chamfer_cut();

    %intersection() {
        hollow_tube_without_inner_chamfers();

        translate([-2, -2, -0.2])
            cube([outer_width + 4, outer_depth + 4, 7]);
    }
}

module stage_07_bottom_chamfer_result() {
    // Apply only the lower inside-chamfer cutter.
    difference() {
        intersection() {
            hollow_tube_without_inner_chamfers();

            translate([-2, -2, -0.2])
                cube([outer_width + 4, outer_depth + 4, 8]);
        }

        inner_chamfer_cut();
    }
}

module stage_08_final() {
    final_tube();
}

module stage_09_chamfer_closeup() {
    // Half-depth cutaway of the lower 8 mm. This shows the outside and
    // inside chamfers together and makes the remaining wall easy to inspect.
    intersection() {
        final_tube();

        translate([-2, -2, -0.2])
            cube([
                outer_width + 4,
                outer_depth / 2 + 2,
                8
            ]);
    }
}

// ---------- Selector ----------

if (design_step == "01_profiles")
    stage_01_profiles();
else if (design_step == "02_outer_chamfer_inputs")
    stage_02_outer_chamfer_inputs();
else if (design_step == "03_outer_hull")
    stage_03_outer_hull();
else if (design_step == "04_hollow_tube")
    stage_04_hollow_tube();
else if (design_step == "05_inner_chamfer_inputs")
    stage_05_inner_chamfer_inputs();
else if (design_step == "06_inner_chamfer_cut")
    stage_06_inner_chamfer_cut();
else if (design_step == "07_bottom_chamfer_result")
    stage_07_bottom_chamfer_result();
else if (design_step == "08_final")
    stage_08_final();
else
    stage_09_chamfer_closeup();
