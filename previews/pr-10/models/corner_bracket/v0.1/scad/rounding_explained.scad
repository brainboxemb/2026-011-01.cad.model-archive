// Understanding round corners: hull() around circles versus
// a sampled circular arc inside an L-shaped corner bracket.
// Independent educational model: no external OpenSCAD library required.

// Choose one step from the OpenSCAD Customizer.
/* [Demonstration] */
demo_stage = "01_four_circles"; // [01_four_circles, 02_hull_of_circles, 03_sharp_L, 04_circle_guide, 05_arc_points, 06_rounded_L, 07_hull_fills_corner]

// Use a deliberately large radius so the construction is easy to see.
// This is a teaching example, NOT the dimensions of the production bracket.
radius = 10;
wall = 14;
armH = 55;
armV = 55;
step_degrees = 5;
$fn = 80;

// Example A: circles at the four corners of a rectangle.
// Their curved outside edges remain on the convex hull.
module four_circles() {
    for (x = [-22, 22], y = [-13, 13])
        translate([x, y]) circle(r = 5);
}

module hull_of_circles() {
    hull() four_circles();
}

// Example B: an L profile with a SHARP concave (inside) corner at (0, 0).
module sharp_L() {
    polygon([
        [0, 0], [armH, 0], [armH, wall],
        [-wall, wall], [-wall, -armV], [0, -armV]
    ]);
}

// Circle centre: (radius, -radius).
// cos()/sin() sample its top-left quarter, from 180° down to 90°.
// Because we explicitly create points, circle() is NOT used to
// construct the actual rounded L polygon.
function arc_point(a) = [
    radius + radius * cos(a),
    -radius + radius * sin(a)
];
arc_points = [for (a = [180 : -step_degrees : 90]) arc_point(a)];

// A single concave polygon with the arc points replacing the sharp corner.
module rounded_L() {
    polygon(concat([
        [armH, 0], [armH, wall],
        [-wall, wall], [-wall, -armV], [0, -armV]
    ], arc_points));
}

// A complete circle is drawn ONLY as a construction guide:
// it shows where the sampled quarter-arc coordinates come from.
module circle_guide() {
    translate([radius, -radius]) {
        difference() {
            circle(r = radius);
            circle(r = radius - 0.4);
        }
        circle(r = 0.9);
    }
}

// Highlight exactly the small sector that the sampled arc adds to the L.
// In the actual model it is part of a polygon, not a separate solid.
module arc_added_region() {
    polygon(concat([[0, 0]], arc_points));
}

// Showing the effect of convex hull on the *whole* concave L:
// the large filled area would destroy the inside recess.
module hull_filled_region() {
    difference() {
        hull() rounded_L();
        rounded_L();
    }
}

if (demo_stage == "01_four_circles") {
    color("RoyalBlue") four_circles();
} else if (demo_stage == "02_hull_of_circles") {
    color("SteelBlue") hull_of_circles();
} else if (demo_stage == "03_sharp_L") {
    color("SteelBlue") sharp_L();
} else if (demo_stage == "04_circle_guide") {
    color("SteelBlue") sharp_L();
    color("Orange") circle_guide();
} else if (demo_stage == "05_arc_points") {
    color("SteelBlue") sharp_L();
    color("Gold") arc_added_region();
    color("Crimson")
        for (p = arc_points)
            translate(p) circle(r = 0.55, $fn = 20);
} else if (demo_stage == "06_rounded_L") {
    color("SteelBlue") rounded_L();
} else if (demo_stage == "07_hull_fills_corner") {
    color("SteelBlue") rounded_L();
    color("Tomato") hull_filled_region();
}
