//! # Example spacer — v0.1
//!
//! Minimal NopSCADlib project used to qualify this archive's workflow.
//! This is a demonstration, **not** an archived production model.
//!
//! Parameters are in millimetres. The model is a 24 mm diameter spacer with
//! an 8.2 mm clearance bore and 6 mm height.
//!
//! For printing, place the flat face on the bed. Material and dimensional
//! tolerances must be selected for the real application.

include <NopSCADlib/core.scad>;

outer_d = 24;
bore_d = 8.2;
spacer_height = 6;
$fn = 96;

//! Single printed spacer. No external hardware is included.
module spacer_stl()
    stl("spacer")
        difference() {
            cylinder(h = spacer_height, d = outer_d);
            translate([0, 0, -0.1])
                cylinder(h = spacer_height + 0.2, d = bore_d);
        }

//! Place the printed spacer on a flat surface.
module main_assembly()
    assembly("main") {
        stl_colour("SteelBlue")
            spacer_stl();
    }

main_assembly();
