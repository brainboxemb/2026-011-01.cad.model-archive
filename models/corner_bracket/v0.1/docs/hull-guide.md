# Understanding `hull()`

This page has **one job**: explain the basic OpenSCAD `hull()`
operation with a simple convex example.

It does **not** explain the Corner Bracket itself. For that, use:

- [Chamfer Guide](chamfer-guide.html) — the actual bracket construction,
  including both real hull operations.
- [Elephant-foot Hull Experiment](ef-hull-experiment.html) — the detailed
  two-surface simplification experiment, including all intermediate shapes.
- [Polygon Guide](polygon-guide.html) — the separate 2D inside-radius
  construction.

## 1. A simple bar

### A. Original bar

![Rectangular bar](../design/hull_01_original_bar.png)

```openscad
module original_bar() {
    translate([0, 0, height/2])
        cube([length, width, height], center=true);
}
```

### B. First hull surface

The lower surface has the full bar size.

![First hull surface](../design/hull_02_wide_layer.png)

```openscad
module wide_layer() {
    translate([0, 0, slice_thickness/2])
        cube([length, width, slice_thickness], center=true);
}
```

### C. Second hull surface

The upper surface is inset by `chamfer`.

![Both hull surfaces before connecting them](../design/hull_03_two_layers.png)

```openscad
module narrow_layer() {
    translate([0, 0, height - slice_thickness/2])
        cube([length - 2*chamfer,
              width  - 2*chamfer,
              slice_thickness], center=true);
}
```

### D. Connect the two surfaces

`hull()` creates the smallest convex solid containing both children.

![Hull connecting the two surfaces](../design/hull_04_hull.png)

```openscad
module sloped_hull() {
    hull() {
        wide_layer();
        narrow_layer();
    }
}
```

The slope comes entirely from the difference between the two input
surfaces. `hull()` does not add a radius or smoothing operation.

### E. Optional clipping

The result can be intersected with another solid if the hull is only
being used as a limiting envelope.

![Hull clipped by the original bar](../design/hull_05_result.png)

```openscad
intersection() {
    original_bar();
    sloped_hull();
}
```

## 2. Applying this to the Corner Bracket

The Corner Bracket uses the same principle twice:

1. an outside `cs` hull creates a limiting envelope;
2. an elephant-foot `ef` hull creates a cutting volume.

The important part is the **input surfaces**. The
[Chamfer Guide](chamfer-guide.html) shows those surfaces and the result
for both operations in the same step-by-step format.

If the question is specifically whether the elephant-foot arm-tip
correction can be absorbed into only those two input surfaces, continue
with the [Elephant-foot Hull Experiment](ef-hull-experiment.html).
