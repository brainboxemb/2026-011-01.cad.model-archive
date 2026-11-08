// OpenSCAD design concepts — visual examples.
//
// This file creates small, deliberately simple illustrations for the
// archive-wide design concepts page. Each stage shows one idea only.

$fn = 48;

concept_step = "01_keep"; // [01_keep,02_cut,03_clip,04_hull_keep,05_hull_cut,06_convexity,07_decompose]

module rounded_box_2d(w=28, d=18, r=4) {
    hull()
        for (x=[r, w-r], y=[r, d-r])
            translate([x,y]) circle(r);
}

module thin_profile(z, scale_delta=0, h=0.18) {
    translate([0,0,z])
        linear_extrude(h)
            offset(delta=scale_delta)
                rounded_box_2d();
}

module chamfer_body() {
    hull() {
        thin_profile(0, -1.5);
        thin_profile(4, 0);
    }
}

module concept_keep() {
    // Green result: geometry we intend to keep.
    color([0.25,0.70,0.40])
        chamfer_body();

    // Ghost the two input layers.
    %thin_profile(0, -1.5, 0.25);
    %thin_profile(4, 0, 0.25);
}

module concept_cut() {
    // Grey body stays.
    color([0.65,0.70,0.76])
        cube([30,22,10]);

    // Red cylinder is not part of the final object: it describes material
    // that will be removed.
    color([0.90,0.25,0.20])
        translate([15,11,-1])
            cylinder(h=12, r=4.5);
}

module concept_clip() {
    // Orange part is intentionally too long.
    color([0.95,0.55,0.18,0.55])
        translate([-6,0,0])
            cube([42,16,8]);

    // Blue box is the allowed final region.
    color([0.20,0.55,0.90,0.30])
        cube([30,16,10]);

    // Green overlap is what intersection() keeps.
    color([0.25,0.70,0.40])
        intersection() {
            translate([-6,0,0]) cube([42,16,8]);
            cube([30,16,10]);
        }
}

module concept_hull_keep() {
    // Same geometric hull as concept_keep(), but shown explicitly as
    // something that becomes the final material.
    color([0.25,0.70,0.40,0.85])
        chamfer_body();

    color([0.95,0.55,0.18])
        thin_profile(0, -1.5, 0.25);

    color([0.20,0.55,0.90])
        thin_profile(4, 0, 0.25);
}

module inner_profile_2d(w=20,d=12,r=3) {
    translate([4,3])
        hull()
            for (x=[r,w-r], y=[r,d-r])
                translate([x,y]) circle(r);
}

module inner_layer(z, expansion=0, h=0.18) {
    translate([0,0,z])
        linear_extrude(h)
            offset(delta=expansion)
                inner_profile_2d();
}

module chamfer_cutter() {
    hull() {
        inner_layer(0, 1.5);
        inner_layer(4, 0);
    }
}

module concept_hull_cut() {
    // Ghost body gives context.
    %cube([30,20,8]);

    // Red hull is only a cutter.
    color([0.90,0.25,0.20,0.85])
        chamfer_cutter();

    color([0.95,0.55,0.18])
        inner_layer(0, 1.5, 0.25);

    color([0.20,0.55,0.90])
        inner_layer(4, 0, 0.25);
}

module l_2d(size=24, wall=7) {
    union() {
        square([size,wall]);
        square([wall,size]);
    }
}

module concept_convexity() {
    // LEFT: convex rounded rectangle. Hull follows the expected outside.
    translate([-34,0,0]) {
        color([0.25,0.70,0.40,0.85])
            hull() {
                translate([0,0,0]) linear_extrude(0.2) offset(delta=-1.3) rounded_box_2d(26,18,4);
                translate([0,0,4]) linear_extrude(0.2) rounded_box_2d(26,18,4);
            }
        %translate([0,0,4]) linear_extrude(0.25) rounded_box_2d(26,18,4);
    }

    // RIGHT: concave L. The red hull bridges the missing inside corner.
    translate([20,0,0]) {
        %translate([0,0,4])
            linear_extrude(0.25)
                l_2d();

        color([0.90,0.25,0.20,0.70])
            hull() {
                translate([0,0,0])
                    linear_extrude(0.2)
                        offset(delta=-1)
                            l_2d();
                translate([0,0,4])
                    linear_extrude(0.2)
                        l_2d();
            }

        // Ghost the missing quadrant so the unwanted bridge is easy to see.
        %translate([7,7,-0.2])
            cube([17,17,4.6]);
    }
}

module concept_decompose() {
    // Four simple construction ideas placed from left to right.

    // 1: outer body
    translate([-54,0,0])
        color([0.25,0.70,0.40])
            cube([20,16,8]);

    // 2: inner void
    translate([-24,0,0]) {
        color([0.65,0.70,0.76])
            cube([20,16,8]);
        color([0.90,0.25,0.20])
            translate([5,4,-1]) cube([10,8,10]);
    }

    // 3: local detail cutter
    translate([6,0,0]) {
        color([0.65,0.70,0.76])
            cube([20,16,8]);
        color([0.90,0.25,0.20])
            translate([15,8,5])
                rotate([0,45,0])
                    cube([8,4,4], center=true);
    }

    // 4: final trimmed result
    translate([38,0,0]) {
        color([0.25,0.70,0.40])
            intersection() {
                translate([-3,0,0]) cube([26,16,8]);
                cube([20,16,10]);
            }
    }
}

if (concept_step == "01_keep")
    concept_keep();
else if (concept_step == "02_cut")
    concept_cut();
else if (concept_step == "03_clip")
    concept_clip();
else if (concept_step == "04_hull_keep")
    concept_hull_keep();
else if (concept_step == "05_hull_cut")
    concept_hull_cut();
else if (concept_step == "06_convexity")
    concept_convexity();
else
    concept_decompose();
