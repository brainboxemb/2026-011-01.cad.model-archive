// Independent regression reference: the former per-edge elephant-foot cuts.
// Keep these historical cutters ONLY in tests, not in the printable model.
// Production chamfers now use hull-based envelopes.
use <../scad/corner_bracket.scad>

// Keep aligned with production defaults. The CI script overrides variations.
W=20;
armH=40;
armV=40;
cs=2;
ef=0.6;
r_in=2;
$fn=48;

test_view="xor"; // [old, new, xor]

module former_wedge_profile() {
    polygon([[W/2-ef-1,-1], [W/2+1,-1], [W/2+1,ef+1]]);
}
module former_edge_wedge(A,U,V,D,len) {
    multmatrix([[U[0], V[0], D[0], A[0]],
                [U[1], V[1], D[1], A[1]],
                [U[2], V[2], D[2], A[2]],
                [0, 0, 0, 1]])
        linear_extrude(height=len)
            polygon([[-ef-1,-1],[1,-1],[1,ef+1]]);
}
module former_ef_cuts() {
    s2=sqrt(2)/2;
    if(ef>0) for(m=[0,1]) mirror([0,m,0]) {
        if(cs>0) {
            former_edge_wedge([armH-cs-s2,W/2+s2,0],
                [s2,s2,0], [0,0,1], [s2,-s2,0], cs*sqrt(2)+2);
            former_edge_wedge([0,W/2-cs-s2,-armV-s2],
                [0,s2,-s2],[-1,0,0],[0,s2,s2],cs*sqrt(2)+2);
        }
        translate([r_in,0,0]) rotate([90,0,90])
            linear_extrude(height=armH+1-r_in) former_wedge_profile();
        translate([0,0,-armV-1]) rotate([0,0,90])
            linear_extrude(height=armV+1-r_in) former_wedge_profile();
        if(r_in>=1)
            translate([r_in,0,-r_in]) rotate([90,0,0]) rotate([0,0,89])
                rotate_extrude(angle=92)
                    polygon([[r_in-1,W/2-ef-1],
                             [r_in-1,W/2+1],
                             [r_in+ef+1,W/2+1]]);
    }
}
module former_bracket() {
    difference() {
        body();
        nut_top();
        nut_side();
        former_ef_cuts();
    }
}
if(test_view=="old") former_bracket();
else if(test_view=="new") bracket();
else if(test_view=="xor")
    union() {
        difference() {former_bracket();bracket();}
        difference() {bracket();former_bracket();}
    }
