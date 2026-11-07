// Beam-first demo of the two edge treatments used by the corner bracket.
//
// The beam has four LONG edges in its rectangular cross-section.
//   - cs is applied to the two upper long edges.
//   - the two lower long edges are deliberately left sharp.
//   - ef is then applied only to those two print-bed edges.
//
// The end faces stay square: they are intentionally outside this lesson.
//
// Set scene to:
//   0 = plain beam
//   1 = normal chamfer cs, bottom still sharp
//   2 = elephant-foot ef only, shown on the original beam
//   3 = cs + ef, the intended final concept

scene = 0;

length = 70;
width = 24;
height = 20;

cs = 3;
ef = 1.2;

// The 2D profile uses:
//   horizontal = beam width
//   vertical   = beam height
//
// It is then extruded along the beam length.
module beam_profile(top_chamfer = 0, bottom_relief = 0) {
    tc = max(0, min(top_chamfer, min(width, height) / 2));
    br = max(0, min(bottom_relief, min(width, height) / 2));

    polygon([
        [br, 0],
        [width - br, 0],
        [width, br],

        [width, height - tc],
        [width - tc, height],
        [tc, height],
        [0, height - tc],

        [0, br]
    ]);
}

// OpenSCAD extrudes a 2D profile along Z. Rotate that extrusion so the beam
// runs horizontally along X while the profile remains width (Y) x height (Z).
module beam(top_chamfer = 0, bottom_relief = 0) {
    translate([0, width, 0])
        rotate([90, 0, 90])
            linear_extrude(height = length)
                beam_profile(top_chamfer, bottom_relief);
}

if (scene == 0) {
    // Reference: all four long edges are sharp.
    beam();
}
else if (scene == 1) {
    // Normal chamfer: ONLY the upper two long edges receive cs.
    // The print-bed edges at the bottom remain sharp.
    beam(top_chamfer = cs);
}
else if (scene == 2) {
    // Isolate ef so its effect is easy to see:
    // ONLY the lower two print-bed edges receive the smaller relief.
    beam(bottom_relief = ef);
}
else {
    // Final concept:
    // normal cs above, smaller ef on the two print-bed edges below.
    beam(top_chamfer = cs, bottom_relief = ef);
}
