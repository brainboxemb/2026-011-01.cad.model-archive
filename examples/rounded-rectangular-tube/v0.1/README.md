# Rounded rectangular tube with end chamfers — v0.1

This standalone OpenSCAD example shows a compact way to build a **hollow rounded rectangular tube** with two different edge treatments:

- a small chamfer on the **outside edge** of both end faces;
- a separate chamfer on the **inside edge** of the hollow opening.

The example is deliberately independent of NopSCADlib. It is meant as a small geometry reference for understanding how hull(), offset(), linear_extrude() and difference() can work together.

![Rounded rectangular tube](figures/rounded_rectangular_tube.png)

The complete source is in [scad/rounded_rectangular_tube.scad](scad/rounded_rectangular_tube.scad).

## Parameters

| Parameter | Default | Meaning |
| --- | ---: | --- |
| outer_width | 30 mm | Outside size in X |
| outer_depth | 20 mm | Outside size in Y |
| length | 60 mm | Tube length in Z |
| wall_thickness | 2.5 mm | Nominal wall thickness |
| outer_radius | 5 mm | Outside corner radius |
| inner_chamfer | 0.6 mm | Chamfer on the hollow inside edge |
| outer_chamfer | 0.4 mm | Chamfer on the outside edge |

The inside width, depth and radius are derived from the outside dimensions and wall thickness.

## 1. Build the rounded 2D profiles

The basic rounded rectangle is made from four circles. hull() wraps those circles with the smallest convex shape that contains them, producing straight sides and rounded corners.

~~~openscad
module rounded_rectangle(width, depth, radius) {
    hull()
        for (x = [radius, width - radius],
             y = [radius, depth - radius])
            translate([x, y])
                circle(radius);
}
~~~

The outer profile uses the requested outside dimensions. The inner profile is shifted inward by the wall thickness and uses a correspondingly smaller radius.

## 2. Create the outside end chamfers

The outer body is not made with one simple extrusion. Instead, three profile layers are supplied to one hull():

1. at the bottom face, the outer profile is inset by outer_chamfer;
2. at Z = outer_chamfer, the profile has its full outside size;
3. at the top face, the profile is inset again.

~~~openscad
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
~~~

The full-size middle section prevents the entire tube from shrinking. The hull only creates a short transition from the smaller end profile to the normal profile at each end.

Conceptually:

~~~text
end face             normal tube
smaller profile  ->  full profile
       \____________
        short chamfer
~~~

## 3. Subtract the continuous hollow interior

The normal inner profile is extruded slightly beyond both ends of the tube and subtracted with difference().

~~~openscad
translate([0, 0, -1])
    linear_extrude(length + 2)
        inner_2d();
~~~

At this stage the tube is hollow, but the inside edge of each end face would still be sharp.

## 4. Create the inside chamfer as a cutting volume

The inside chamfer uses the opposite idea: instead of making the solid smaller at the end face, it makes the **hole larger** at the end face.

The cutting volume is a hull between:

- an enlarged inner opening at the end face;
- the normal inner opening inner_chamfer millimetres farther into the tube.

~~~openscad
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
~~~

Subtracting this volume removes only the small tapered ring around the inside edge. The same cutter is mirrored at the top end.

So the two chamfers are made in different ways:

| Edge | Construction |
| --- | --- |
| Outside end edge | Build a smaller end profile into the **solid** |
| Inside end edge | Subtract a larger end profile from the **hollow opening** |

That distinction is the main idea demonstrated by this example.

## 5. Why epsilon exists

epsilon = 0.01 mm gives the very thin helper layers a real thickness and lets subtractive geometry overlap slightly.

That avoids depending on perfectly coincident faces in Boolean operations. It is a construction tolerance for the CAD model, not a print tolerance.

## Complete construction

The final module is intentionally simple:

~~~openscad
module rounded_rectangular_tube() {
    difference() {
        outer_body();

        // Continuous hollow interior.
        translate([0, 0, -1])
            linear_extrude(length + 2)
                inner_2d();

        // Inside chamfer at both ends.
        inner_chamfer_cut();

        translate([0, 0, length])
            mirror([0, 0, 1])
                inner_chamfer_cut();
    }
}
~~~

This example is useful when a part needs a rounded rectangular shell and the two end-edge treatments need to remain independently adjustable.
