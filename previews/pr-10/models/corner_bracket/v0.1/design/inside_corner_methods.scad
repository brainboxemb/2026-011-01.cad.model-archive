// Compare two easily understandable ways to make a concave corner fillet:
// (A) 2D shapes: square() minus circle(), union() with a 2D L, then extrude.
// (B) 3D solids: cube() minus cylinder(), union() with an extruded L.
// A third view shows the original point-list polygon method.
// Standalone teaching model. The production bracket remains unchanged.

/* [Demonstration] */
demo_stage = "01_sharp_2d"; // [01_sharp_2d, 02_square_circle_2d, 03_piece_2d, 04_rounded_2d, 05_extruded_2d, 06_cube_cylinder_3d, 07_piece_3d, 08_rounded_3d, 09_polygon_points_2d]

/* [Dimensions in mm] */
radius = 12;
wall = 18;
armH = 70;
armV = 70;
depth = 20;

/* [Hidden] */
// 72 facets gives 5-degree segments, comparable with corner_arc in v0.1.
$fn = 72;
epsilon = 0.2;

// 2D L in the XY plane. (0,0) is its originally sharp inside corner.
module sharp_L_2d() {
    polygon([
        [0, 0], [armH, 0], [armH, wall],
        [-wall, wall], [-wall, -armV], [0, -armV]
    ]);
}

// 2D "square minus circle" in the empty lower-right quadrant.
// It fills ONLY the small curved part, leaving the L shape open.
module corner_square_2d() {
    translate([0, -radius]) square([radius, radius]);
}
module corner_circle_2d() {
    translate([radius, -radius]) circle(r = radius);
}
module corner_piece_2d() {
    difference() {
        corner_square_2d();
        corner_circle_2d();
    }
}
module rounded_L_2d() {
    union() {
        sharp_L_2d();
        corner_piece_2d();
    }
}

// Take the same design from 2D into 3D in a single extrusion.
module extruded_from_2d() {
    linear_extrude(height = depth)
        rounded_L_2d();
}

// Alternative: create the curved add-on in 3D, from a cube and a cylinder.
// The subtraction extends slightly above/below the cube to avoid coplanar
// boolean faces. It does not change the outer dimensions of the result.
module corner_cube_3d() {
    translate([0, -radius, 0])
        cube([radius, radius, depth]);
}
module corner_cylinder_3d() {
    translate([radius, -radius, -epsilon])
        cylinder(r = radius, h = depth + 2 * epsilon);
}
module corner_piece_3d() {
    difference() {
        corner_cube_3d();
        corner_cylinder_3d();
    }
}
module rounded_L_3d() {
    union() {
        linear_extrude(height = depth) sharp_L_2d();
        corner_piece_3d();
    }
}

// Original v0.1 idea: calculate vertices along 180..90 degrees and include
// them directly in ONE polygon rather than building a separate 2D piece.
corner_arc_points = [
    for (a = [180 : -5 : 90])
        [radius + radius * cos(a), -radius + radius * sin(a)]
];
module rounded_L_from_points() {
    polygon(concat([
        [armH, 0], [armH, wall],
        [-wall, wall], [-wall, -armV], [0, -armV]
    ], corner_arc_points));
}

// Select intermediate steps with the Customizer dropdown.
// Transparent construction geometry is ONLY for the illustrations.
if (demo_stage == "01_sharp_2d") {
    color("SteelBlue") sharp_L_2d();
} else if (demo_stage == "02_square_circle_2d") {
    color("RoyalBlue") corner_square_2d();
    color("Orange", 0.65) corner_circle_2d();
} else if (demo_stage == "03_piece_2d") {
    color("Orange") corner_piece_2d();
} else if (demo_stage == "04_rounded_2d") {
    color("SteelBlue") sharp_L_2d();
    color("Orange") corner_piece_2d();
} else if (demo_stage == "05_extruded_2d") {
    color("SteelBlue") extruded_from_2d();
} else if (demo_stage == "06_cube_cylinder_3d") {
    color("RoyalBlue") corner_cube_3d();
    color("Orange", 0.65) corner_cylinder_3d();
} else if (demo_stage == "07_piece_3d") {
    color("Orange") corner_piece_3d();
} else if (demo_stage == "08_rounded_3d") {
    color("SteelBlue") rounded_L_3d();
} else if (demo_stage == "09_polygon_points_2d") {
    color("SteelBlue") rounded_L_from_points();
}
