// Optional section clipping for OpenSCAD Customizer inspection.
// The bracket's default "None" mode passes the geometry through unchanged.
// For X/Y/Z, intersect geometry with a slab of the requested depth in mm.
module util_section_inspect(axis = "None", position_mm = 0, depth_mm = 10, direction = "Positive") {
    if (axis == "None")
        children();
    else {
        extent = 10000;
        low = (direction == "Negative") ? position_mm - depth_mm : position_mm;
        intersection() {
            children();
            if (axis == "X")
                translate([low, -extent / 2, -extent / 2])
                    cube([depth_mm, extent, extent]);
            else if (axis == "Y")
                translate([-extent / 2, low, -extent / 2])
                    cube([extent, depth_mm, extent]);
            else if (axis == "Z")
                translate([-extent / 2, -extent / 2, low])
                    cube([extent, extent, depth_mm]);
        }
    }
}
