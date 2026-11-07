// Regression fixture: compare the current square-minus-circle corner
// with the former 19-point arc. No production CAD depends on this file.
// An empty symmetric difference means the 2D outlines are equivalent.
use <../scad/corner_bracket.scad>

// Match the production defaults. -D can override these to test variants.
r_in = 2;
ef = 0.6;
armH = 40;
armV = 40;
t = 10;
c = 3;
ce = 6;

legacy_arc = (r_in > 0)
    ? [for (a = [180 : -5 : 90])
        [r_in + r_in * cos(a), -r_in + r_in * sin(a)]]
    : [[0, 0]];
legacy_tip_top = (ef > 0)
    ? [[armH - ef, 0], [armH, ef]]
    : [[armH, 0]];
legacy_tip_vert = (ef > 0)
    ? [[-ef, -armV], [0, -armV + ef]]
    : [[0, -armV]];

module legacy_profile() {
    polygon(concat(legacy_tip_top, [
        [armH, t - c],
        [armH - c, t],
        [-t + ce, t],
        [-t, t - ce],
        [-t, -armV + c],
        [-t + c, -armV]
    ], legacy_tip_vert, legacy_arc));
}

// The two differences must both be empty. Extrude to make OpenSCAD
// evaluate the result with its full solid geometry engine.
linear_extrude(height = 1)
    union() {
        difference() { profile(); legacy_profile(); }
        difference() { legacy_profile(); profile(); }
    }
