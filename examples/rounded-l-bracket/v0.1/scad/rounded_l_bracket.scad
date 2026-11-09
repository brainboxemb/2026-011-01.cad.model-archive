//! # Rounded L bracket with end chamfers — v0.1
//!
//! Standalone OpenSCAD example showing an L-shaped shell built from a convex
//! rounded outer profile and a convex rounded inner cutout.
//! Both profiles intentionally extend past the final leg lengths; the ends are
//! trimmed flat only after the chamfers and hollow section have been created.
//!
//! All dimensions are in millimetres.

$fn = 64;

leg_x          = 40;   // leg length along X
leg_y          = 30;   // leg length along Y
height         = 20;   // height along Z
wall_thickness = 2.5;  // wall thickness
outer_radius   = 5;    // outside corner radius
inner_chamfer  = 0.6;  // chamfer on the inside edge
outer_chamfer  = 0.4;  // chamfer on the outside edge

epsilon      = 0.01;
inner_radius = max(outer_radius - wall_thickness, 0.01);

// Both profiles extend 2 mm beyond the final leg ends and are trimmed later.
profile_x = leg_x + 2;
profile_y = leg_y + 2;

// Convex outer profile with one rounded corner at (0, 0).
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

// Convex inner cutout with one rounded corner at
// (wall_thickness, wall_thickness).
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

// Outer solid with a chamfer at the bottom and top.
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

module rounded_l_bracket() {
    intersection() {
        difference() {
            outer_body();

            // Continuous inner cutout.
            translate([0, 0, -1])
                linear_extrude(height + 2)
                    inner_2d();

            // Inside chamfer at the bottom and top.
            inner_chamfer_cut();

            translate([0, 0, height])
                mirror([0, 0, 1])
                    inner_chamfer_cut();
        }

        // Trim the leg ends flat at leg_x and leg_y.
        translate([0, 0, -1])
            cube([leg_x, leg_y, height + 2]);
    }
}

rounded_l_bracket();
