//! # Rounded rectangular tube with end chamfers — v0.1
//!
//! Standalone OpenSCAD example showing a hollow rounded rectangular tube.
//! The outside receives a chamfer at both end faces; the hollow inside gets
//! a separate chamfer at both ends.
//!
//! All dimensions are in millimetres.

$fn = 64;

outer_width   = 30;    // outer width (X)
outer_depth   = 20;    // outer depth (Y)
length        = 60;    // tube length (Z)
wall_thickness = 2.5;  // wall thickness
outer_radius  = 5;     // outside corner radius

inner_chamfer = 0.6;   // chamfer on the inside edge
outer_chamfer = 0.4;   // chamfer on the outside edge; must be smaller than outer_radius

epsilon = 0.01;

// Inner dimensions and inner corner radius.
inner_width  = outer_width - 2 * wall_thickness;
inner_depth  = outer_depth - 2 * wall_thickness;
inner_radius = max(outer_radius - wall_thickness, 0.01);

// Rounded rectangular 2D profile.
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

// Outer solid with a chamfer on both end faces.
module outer_body() {
    hull() {
        // Bottom face: inset by outer_chamfer.
        translate([0, 0, 0])
            linear_extrude(epsilon)
                offset(delta = -outer_chamfer)
                    outer_2d();

        // Full outer size between the two end chamfers.
        translate([0, 0, outer_chamfer])
            linear_extrude(length - 2 * outer_chamfer)
                outer_2d();

        // Top face: inset by outer_chamfer.
        translate([0, 0, length - epsilon])
            linear_extrude(epsilon)
                offset(delta = -outer_chamfer)
                    outer_2d();
    }
}

// Cutting volume for one inside chamfer.
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

module rounded_rectangular_tube() {
    difference() {
        outer_body();

        // Continuous hollow interior.
        translate([0, 0, -1])
            linear_extrude(length + 2)
                inner_2d();

        // Inside chamfer at the bottom and top end.
        inner_chamfer_cut();

        translate([0, 0, length])
            mirror([0, 0, 1])
                inner_chamfer_cut();
    }
}

rounded_rectangular_tube();
