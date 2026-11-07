# Beam demo: the corner where the chamfers meet

This example represents **one straight arm tip** of the Corner Bracket.

The important point is that the **kopse kant is part of the geometry too**.
The previous beam version only showed the long edges and was therefore still
missing part of the real situation.

There are three relevant edge treatments:

- `c`: the normal upper chamfer in the end profile;
- `cs`: the chamfer around the printed side faces;
- `ef`: the elephant-foot relief at the bottom, both along the long contact
  edges **and across the lower end profile**.

The problem appears at the lower corner where those surfaces meet.

## 0. Plain beam

![Plain beam](renders/00_plain_beam.png)

Nothing is chamfered yet.

## 1. Normal chamfers, including the end face

![Beam with normal end and side chamfers](renders/01_normal_chamfers.png)

This step now includes both parts that belong to the normal geometry:

1. the upper corner of each **kopse kant** is chamfered with `c`;
2. the printed side faces are chamfered with `cs`.

The lower edge is still left for the elephant-foot correction.

This is important because the beam end must not remain a square block while we
try to explain the real bracket arm.

## 2. Add the complete elephant-foot relief

The elephant-foot treatment is also not limited to the two long bottom edges.

It consists of both:

- the `ef` relief along the long lower contact edges;
- the `ef` chamfer across the **lower kopse kant**.

That means the bottom correction now wraps through the end of the beam instead
of stopping before it.

The image below crops the lower end corner where the complete `ef` geometry
meets the diagonal `cs` side bevel.

![Junction before the local correction](renders/02_junction_problem.png)

This is the junction we actually want to understand.

## 3. The local miter correction

The broad `ef` construction by itself does not give the desired transition at
that 3D meeting point. A small triangular cutter is therefore swept along the
diagonal junction.

![Isolated local miter cutter](renders/03_miter_cutter.png)

The correction is local. It does not redefine the normal chamfers or the broad
elephant-foot relief.

## 4. Corrected lower corner

![Junction after the miter correction](renders/04_junction_fixed.png)

The cropped view now contains all relevant surfaces:

- the end-face `ef` chamfer;
- the long bottom `ef` relief;
- the diagonal `cs` side bevel;
- the small miter correction between them.

## 5. Complete beam

![Complete corrected beam](renders/05_final_beam.png)

Only after the junction is clear do we return to the full beam.

The mapping back to the real Corner Bracket is now direct:

**beam kopse kant ↔ arm tip**

**upper end chamfer `c` ↔ existing arm-end chamfer**

**side-face chamfer `cs` ↔ side-edge bevel**

**lower end + long-edge `ef` ↔ elephant-foot relief**

**small miter hull ↔ `relief_corner_miters()`**

## Source

The complete demonstration is in
[`scad/hull_operations.scad`](scad/hull_operations.scad).

The scenes are:

- `00_plain`
- `01_normal_chamfers`
- `02_problem`
- `03_miter`
- `04_fixed`
- `05_final`
