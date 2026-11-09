// Experiment: can one hull form both an upper chamfer and elephant-foot relief?
// This is a deliberately CONVEX straight-arm test piece, not the full L bracket.
// The full bracket has a concave inside corner, a radius, end chamfers and
// captive-nut openings. Do not substitute this prototype for corner_bracket.scad.

/* [Experiment] */
view = "comparison"; // [comparison, combined, reference, xor, layers]
length = 40;
width = 20;
height = 10;
upper_chamfer = 2; // comparable to the bracket's side_edge_chamfer
elephant_foot = 0.6; // experimental print-relief amount
separation = 12;

/* [Hidden] */
eps = 0.001;
assert(length > 2 * max(upper_chamfer, elephant_foot));
assert(width > 2 * max(upper_chamfer, elephant_foot));
assert(height > upper_chamfer + elephant_foot + 4 * eps);

// A rectangular horizontal layer, inset equally from four sides.
// A tiny thickness makes this legal 3D input for hull().
module layer(z, inset) {
    translate([inset, inset, z])
        cube([length - 2 * inset, width - 2 * inset, eps]);
}

// All four outlines belong to ONE hull() operation.
// Bottom-to-middle slope = elephant-foot relief.
// Middle-to-top slope = upper chamfer.
// The intervening straight part remains at full size.
module combined_hull() {
    hull() {
        layer(0, elephant_foot);
        layer(elephant_foot, 0);
        layer(height - upper_chamfer - eps, 0);
        layer(height - eps, upper_chamfer);
    }
}

// Comparison reference: each section is separately lofted.
// This is independent of the single four-layer hull construction.
module reference_sections() {
    union() {
        hull() { layer(0, elephant_foot); layer(elephant_foot, 0); }
        hull() { layer(elephant_foot, 0); layer(height - upper_chamfer - eps, 0); }
        hull() { layer(height - upper_chamfer - eps, 0); layer(height - eps, upper_chamfer); }
    }
}

module symmetric_difference() {
    union() {
        difference() { combined_hull(); reference_sections(); }
        difference() { reference_sections(); combined_hull(); }
    }
}

if (view == "combined") combined_hull();
else if (view == "reference") reference_sections();
else if (view == "xor") symmetric_difference();
else if (view == "layers") {
    color("orange") layer(0, elephant_foot);
    color("gold") layer(elephant_foot, 0);
    color("cyan") layer(height - upper_chamfer - eps, 0);
    color("blue") layer(height - eps, upper_chamfer);
} else {
    color("steelblue") combined_hull();
    translate([length + separation, 0, 0]) color("orange") reference_sections();
}
