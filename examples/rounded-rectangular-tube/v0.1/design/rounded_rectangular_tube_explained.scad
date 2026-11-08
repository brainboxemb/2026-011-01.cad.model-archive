// Rounded rectangular tube — construction walkthrough.
//
// This file is deliberately separate from the printable example.
// It exposes the intermediate geometry used to create the two end chamfers
// and ends with a cutaway close-up of the finished lower end.

$fn = 64;

design_step = "09_chamfer_closeup"; // [01_profiles,02_outer_chamfer_inputs,03_outer_hull,04_hollow_tube,05_inner_chamfer_inputs,06_inner_chamfer_cut,07_bottom_chamfer_result,08_final,09_chamfer_closeup]

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

// Cutaway of the lower end so the outside and inside chamfers can be
// inspected together. Only half the depth is kept and only the lowest
// 8 mm of the tube is shown.
module chamfer_closeup_stage() {
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
    chamfer_closeup_stage();
