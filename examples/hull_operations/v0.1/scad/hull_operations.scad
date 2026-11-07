// Minimal visual demo for the two hull-based edge operations used by the corner bracket.
//
// Set scene to:
//   0 = plain beam
//   1 = side chamfer only (cs)
//   2 = elephant-foot relief only (ef)
//   3 = both operations
//
// The geometry is deliberately a simple beam. No L-profile, holes, nuts or
// rounded inside corner are present here.

scene = 0;

length = 70;
width = 24;
height = 20;

cs = 3;
ef = 1.2;

$fn = 48;

module plain_beam() {
    cube([length, width, height]);
}

// A simple visual equivalent of the side-edge chamfer operation:
// keep the full-width section in the middle and connect it with a narrower
// section on each outer face.
module side_chamfered_beam() {
    hull() {
        translate([0, cs, 0])
            cube([length, width - 2 * cs, 0.01]);

        translate([0, 0, cs])
            cube([length, width, height - 2 * cs]);

        translate([0, cs, height - 0.01])
            cube([length, width - 2 * cs, 0.01]);
    }
}

// Elephant-foot relief is easier to understand as a subtraction:
// the bottom contact edge is moved inward by ef over a short height.
// We deliberately show the removed volume separately in the demo scenes.
module ef_relief_volume() {
    hull() {
        translate([0, 0, 0])
            cube([length, width, 0.01]);

        translate([0, ef, ef])
            cube([length, width - 2 * ef, 0.01]);
    }
}

module ef_relief_beam() {
    difference() {
        plain_beam();
        difference() {
            ef_relief_volume();
            translate([-1, ef, -1])
                cube([length + 2, width - 2 * ef, ef + 2]);
        }
    }
}

module combined_beam() {
    difference() {
        side_chamfered_beam();
        difference() {
            ef_relief_volume();
            translate([-1, ef, -1])
                cube([length + 2, width - 2 * ef, ef + 2]);
        }
    }
}

if (scene == 0) {
    plain_beam();
}
else if (scene == 1) {
    side_chamfered_beam();
}
else if (scene == 2) {
    ef_relief_beam();
}
else {
    combined_beam();
}
