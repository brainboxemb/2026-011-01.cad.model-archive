// OpenSCAD design concepts — visual examples.
//
// Each illustration is deliberately simple. Whenever possible it shows
// INPUT on the left and RESULT on the right so the operation can be read
// from the picture before reading the text.

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

module arrow_x(length=11) {
    color([0.25,0.25,0.25]) {
        rotate([0,90,0])
            cylinder(h=length-2.2, r=0.45);
        translate([length-2.2,0,0])
            rotate([0,90,0])
                cylinder(h=2.2, r1=1.35, r2=0);
    }
}

module concept_keep() {
    // LEFT: the two profiles we start from, pulled apart so both are obvious.
    translate([-40,0,0]) {
        color([0.95,0.55,0.18])
            thin_profile(0, -1.5, 0.28);
        color([0.20,0.55,0.90])
            thin_profile(7, 0, 0.28);
    }

    translate([-4,9,3.5])
        arrow_x(11);

    // RIGHT: the material produced by joining the profiles is kept.
    translate([18,0,0])
        color([0.25,0.70,0.40])
            chamfer_body();
}

module concept_cut() {
    // LEFT: body plus red volume that describes what must disappear.
    translate([-42,0,0]) {
        color([0.65,0.70,0.76])
            cube([30,22,10]);
        color([0.90,0.25,0.20])
            translate([15,11,-1])
                cylinder(h=12, r=4.5);
    }

    translate([-5,11,5])
        arrow_x(11);

    // RIGHT: difference() result.
    translate([20,0,0])
        color([0.25,0.70,0.40])
            difference() {
                cube([30,22,10]);
                translate([15,11,-1])
                    cylinder(h=12, r=4.5);
            }
}

module concept_clip() {
    // LEFT: orange part is too long.
    translate([-44,0,0]) {
        color([0.95,0.55,0.18])
            translate([-6,0,0])
                cube([42,16,8]);

        // Blue plate floats above it and shows the allowed X/Y footprint.
        // Keeping it separate avoids hiding the orange overhang.
        color([0.20,0.55,0.90])
            translate([0,0,11])
                cube([30,16,0.8]);
    }

    translate([-3,8,4])
        arrow_x(11);

    // RIGHT: only the part inside that footprint remains.
    translate([20,0,0])
        color([0.25,0.70,0.40])
            intersection() {
                translate([-6,0,0]) cube([42,16,8]);
                cube([30,16,10]);
            }
}

module concept_hull_keep() {
    // LEFT: the hull inputs.
    translate([-40,0,0]) {
        color([0.95,0.55,0.18])
            thin_profile(0, -1.5, 0.28);
        color([0.20,0.55,0.90])
            thin_profile(7, 0, 0.28);
    }

    translate([-4,9,3.5])
        arrow_x(11);

    // RIGHT: the hull itself is the wanted body.
    translate([18,0,0])
        color([0.25,0.70,0.40])
            chamfer_body();
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

module hollow_body_with_chamfer() {
    difference() {
        cube([30,20,8]);

        // Normal opening continues through the whole body.
        translate([0,0,-1])
            linear_extrude(10)
                inner_profile_2d();

        // The tapered cutter enlarges the opening only near the end face.
        chamfer_cutter();
    }
}

module concept_hull_cut() {
    // LEFT: two opening profiles.
    translate([-55,0,0]) {
        color([0.95,0.55,0.18])
            inner_layer(0, 1.5, 0.28);
        color([0.20,0.55,0.90])
            inner_layer(7, 0, 0.28);
    }

    translate([-27,9,3.5])
        arrow_x(9);

    // MIDDLE: hull turns them into a solid cutter.
    translate([-12,0,0])
        color([0.90,0.25,0.20])
            chamfer_cutter();

    translate([18,9,3.5])
        arrow_x(9);

    // RIGHT: subtract the normal opening and the cutter from the body.
    translate([34,0,0])
        color([0.25,0.70,0.40])
            hollow_body_with_chamfer();
}

module l_2d(size=24, wall=7) {
    union() {
        square([size,wall]);
        square([wall,size]);
    }
}

module concept_convexity() {
    // LEFT: a convex rounded rectangle. Its convex hull changes nothing.
    translate([-34,0,0]) {
        color([0.25,0.70,0.40])
            linear_extrude(0.8)
                hull()
                    rounded_box_2d(26,18,4);
    }

    // RIGHT: grey is the intended L. Red underneath is hull(L).
    // The red triangle visible in the missing corner is the unwanted bridge.
    translate([20,0,0]) {
        color([0.90,0.25,0.20])
            linear_extrude(0.6)
                hull()
                    l_2d();

        color([0.65,0.70,0.76])
            translate([0,0,0.8])
                linear_extrude(0.6)
                    l_2d();
    }
}

module base_with_main_void(length=26) {
    difference() {
        cube([length,16,8]);
        translate([6,4,-1])
            cube([12,8,10]);
    }
}

module base_with_local_cut(length=26) {
    difference() {
        base_with_main_void(length);
        translate([length-2,8,6])
            rotate([0,45,0])
                cube([8,5,5], center=true);
    }
}

module concept_decompose() {
    // 1: start with an easy outside body.
    translate([-63,0,0])
        color([0.25,0.70,0.40])
            cube([26,16,8]);

    translate([-33,8,4])
        arrow_x(7);

    // 2: subtract the main void.
    translate([-21,0,0])
        color([0.25,0.70,0.40])
            base_with_main_void();

    translate([9,8,4])
        arrow_x(7);

    // 3: subtract a small local detail.
    translate([21,0,0])
        color([0.25,0.70,0.40])
            base_with_local_cut();

    translate([51,8,4])
        arrow_x(7);

    // 4: trim the overlong end to the final length.
    translate([63,0,0])
        color([0.25,0.70,0.40])
            intersection() {
                base_with_local_cut();
                cube([22,16,10]);
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
