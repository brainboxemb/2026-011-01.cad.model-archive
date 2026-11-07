// Corner Bracket cs/ef junction demo.
//
// Visual rule:
//   * the SAME real L-shaped bracket stays in place;
//   * NO detached section planes are shown;
//   * the local horizontal arm tip is explained with two full 3D arm volumes,
//     just like the successful beam demo.
//
// This remains an experiment. The production corner_bracket.scad is unchanged.

/* [Illustration] */
junction_step = "00_l_with_cs"; // [00_l_with_cs, 01_current_result, 02_proposed_inputs, 03_proposed_hull, 04_proposed_result]

/* [Display] */
show_closeup = false;

/* [Hidden] */
use <../scad/corner_bracket.scad>

$fn = 48;
eps = 0.02;

armH = 40;
armV = 40;
t = 10;
W = 20;
cs = 2;
ef = 0.6;

// -----------------------------------------------------------------------------
// View helpers
// -----------------------------------------------------------------------------

module tip_crop() {
    translate([armH - cs - ef - 5, W / 2 - cs - ef - 5, -2])
        cube([cs + ef + 10, cs + ef + 10, t + 4]);
}

module view_part() {
    if (show_closeup)
        intersection() {
            children();
            tip_crop();
        }
    else
        children();
}

// The arm tip we care about is the horizontal arm. Keep it as a genuine 3D
// volume cut from the already-cs-chamfered real body().
module horizontal_arm_cs() {
    intersection() {
        body();
        translate([-1, -W, -1])
            cube([armH + 2, 2 * W, t + 2]);
    }
}

// -----------------------------------------------------------------------------
// Current result: broad production ef hulls, before special corner miters.
// -----------------------------------------------------------------------------

module current_pre_miter_body() {
    difference() {
        body();
        inside_relief_envelope();
    }
}

// -----------------------------------------------------------------------------
// Proposed beam-style local construction on the real arm
// -----------------------------------------------------------------------------
//
// The beam experiment worked when BOTH ef inputs already contained cs.
//
// Here we do exactly that on the horizontal arm tip:
//
//   lower input  = actual cs-chamfered horizontal arm, reduced by ef at the
//                  print/contact boundary;
//   upper input  = actual cs-chamfered horizontal arm from z=ef upward.
//
// Both are full 3D arm-shaped objects. No projection plates are displayed.

// Keep the already-cs-chamfered arm from z=ef upward.
module proposed_upper_arm() {
    intersection() {
        horizontal_arm_cs();
        translate([-2, -W, ef])
            cube([armH + 4, 2 * W, t + 4]);
    }
}

// Build the lower ef input from the actual cs arm itself.
//
// We remove an ef-wide shell from the bottom/contact perimeter by intersecting
// the cs arm with an inset bounding region. The diagonal cs tip geometry is
// therefore already present before hull().
module proposed_lower_arm() {
    intersection() {
        horizontal_arm_cs();

        // ef inset from both printed side faces and the arm tip/contact edges.
        translate([ef, -W / 2 + ef, 0])
            cube([
                armH - 2 * ef,
                W - 2 * ef,
                ef + eps
            ]);
    }
}

// Hull only these two LOCAL horizontal-arm volumes.
// The full L is never hulled globally, so its concave inside corner is not
// filled in.
module proposed_arm_hull() {
    hull() {
        proposed_lower_arm();
        proposed_upper_arm();
    }
}

// Replace only the horizontal arm-tip region with the proposed local hull.
// Everything else remains the existing cs body.
//
// This is intentionally a visual/minimal experiment, not yet production code.
module proposed_body() {
    union() {
        // Keep the full real L except the local horizontal-arm volume.
        difference() {
            body();
            translate([-1, -W, -1])
                cube([armH + 2, 2 * W, t + 2]);
        }

        // Put the proposed cs-aware/ef hull back in that local arm region.
        intersection() {
            proposed_arm_hull();
            translate([-1, -W, -1])
                cube([armH + 2, 2 * W, t + 2]);
        }
    }
}

// -----------------------------------------------------------------------------
// Scenes
// -----------------------------------------------------------------------------

if (junction_step == "00_l_with_cs") {
    color("SteelBlue")
        view_part()
            body();
}

else if (junction_step == "01_current_result") {
    color("SteelBlue")
        view_part()
            current_pre_miter_body();
}

else if (junction_step == "02_proposed_inputs") {
    // Keep the entire L faintly visible.
    color("SteelBlue", 0.14)
        view_part()
            body();

    // Two REAL 3D arm volumes, overlaid in place.
    color("DeepSkyBlue", 0.46)
        view_part()
            proposed_lower_arm();

    color("DarkOrange", 0.30)
        view_part()
            proposed_upper_arm();
}

else if (junction_step == "03_proposed_hull") {
    color("SteelBlue", 0.14)
        view_part()
            body();

    color("SeaGreen", 0.52)
        view_part()
            proposed_arm_hull();
}

else {
    color("SeaGreen")
        view_part()
            proposed_body();
}
