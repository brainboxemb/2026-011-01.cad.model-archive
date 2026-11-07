// A small, independent example showing what hull() does in OpenSCAD.
// The real corner bracket uses the same idea with a more complicated outline.
// Select a stage in the Customizer; no external library is required.

/* [Demonstration] */
demo_stage = "01_original_bar"; // [01_original_bar, 02_wide_layer, 03_two_layers, 04_hull, 05_result]

// All dimensions in millimetres.
length = 60;
width = 26;
height = 14;
chamfer = 5;
slice_thickness = 0.5;

// A plain bar: the starting shape whose sharp edges we want to soften.
module original_bar() {
    translate([0, 0, height / 2])
        cube([length, width, height], center = true);
}

// First input to hull(): a full-size, thin layer at the bottom.
module wide_layer() {
    translate([0, 0, slice_thickness / 2])
        cube([length, width, slice_thickness], center = true);
}

// Second input: a smaller layer at the top, leaving room for bevels.
module narrow_layer() {
    translate([0, 0, height - slice_thickness / 2])
        cube([length - 2 * chamfer, width - 2 * chamfer, slice_thickness],
             center = true);
}

// hull() wraps both layers in the smallest possible convex solid.
// The connections between the wide and narrow layers become slopes.
module sloped_hull() {
    hull() {
        wide_layer();
        narrow_layer();
    }
}

// intersection() keeps only volume shared by the bar and hull.
// Here the hull is entirely inside the bar, so the result equals the hull.
// In the actual L bracket, this clipping is more useful.
module clipped_bar() {
    intersection() {
        original_bar();
        sloped_hull();
    }
}

if (demo_stage == "01_original_bar") {
    color("LightSlateGray") original_bar();
} else if (demo_stage == "02_wide_layer") {
    color("RoyalBlue") wide_layer();
} else if (demo_stage == "03_two_layers") {
    color("RoyalBlue") wide_layer();
    color("Orange") narrow_layer();
} else if (demo_stage == "04_hull") {
    color("SteelBlue") sloped_hull();
} else if (demo_stage == "05_result") {
    // Side-by-side: the original square-edged bar and the bevelled result.
    translate([-38, 0, 0]) color("LightSlateGray") original_bar();
    translate([38, 0, 0]) color("SteelBlue") clipped_bar();
}
