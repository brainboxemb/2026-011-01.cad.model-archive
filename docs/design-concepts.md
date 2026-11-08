# OpenSCAD design concepts

This page collects reusable modelling ideas that apply across the archive.
The goal is not to prescribe one OpenSCAD command for every situation, but to
make the **role of each construction shape** explicit before choosing the
Boolean operation.

## Start with the role of the geometry

A useful way to read or design an OpenSCAD model is to classify temporary
geometry into three roles:

| Role | Question | Typical operation |
| --- | --- | --- |
| **Keep geometry** | What material or envelope do I want to keep? | direct solid, `union()`, sometimes `hull()` |
| **Cut geometry** | What material do I want to remove? | `difference()` |
| **Clip / trim geometry** | What final region is allowed to remain? | `intersection()` |

These roles describe **design intent**. They are more useful than rules such as
"outside geometry uses one command and inside geometry uses another".

The same OpenSCAD primitive can serve different roles. A `hull()`, for
example, can generate material that remains in the part or a temporary volume
that is later subtracted.

## hull() is a shape generator, not a Boolean role

`hull()` creates the smallest **convex** shape containing all of its inputs.

That makes it very useful for connecting two related profiles:

~~~text
profile A
   ↓
 hull()
   ↓
profile B
~~~

If profile A and profile B are differently sized layers, the hull naturally
creates the sloped transition between them.

But what that transition *means* depends on how the result is used.

### Pattern 1 — hull() creates material to keep

A smaller outside profile can be connected to the normal outside profile:

~~~text
smaller outer profile
         ↓
       hull()
         ↓
normal outer profile
         =
sloped outside body
~~~

The hull result is the actual solid or envelope that remains in the model.

### Pattern 2 — hull() creates material to remove

A larger opening can be connected to the normal opening:

~~~text
larger opening
      ↓
    hull()
      ↓
normal opening
      =
tapered cutting volume
      ↓
 difference()
~~~

Here the hull itself is not part of the final object. It is simply the easiest
way to describe the material that must disappear.

So there is no general rule that an "inside" feature must be a cutter or an
"outside" feature must be kept. Use whichever representation makes the desired
geometry simplest and clearest.

## difference() — describe what should disappear

`difference()` is usually easiest to understand when the unwanted material
has a simple shape.

~~~openscad
difference() {
    body();
    cut();
}
~~~

This is often a good fit for:

- holes;
- pockets;
- clearances;
- chamfers around an opening;
- local print compensation;
- reliefs.

A subtractive construction is not inferior to a constructive one. If the
material to remove is easier to describe than the final remaining surface,
the cutter is often the clearer model.

## intersection() — constrain or trim, do not confuse it with the feature

`intersection()` keeps only material present in **all** supplied shapes.

~~~openscad
intersection() {
    overbuilt_part();
    final_bounds();
}
~~~

A useful pattern is to deliberately build geometry slightly too large or too
long, then apply the exact final boundary once at the end.

This separates two concerns:

~~~text
first:   construct the feature cleanly
then:    enforce the final bounds
~~~

For example, a chamfer can be generated on a continuous overlong profile while
a final trim box later sets the exact end position.

In that construction, `intersection()` does **not** create the chamfer. It
only clips the already-created geometry to its allowed final region.

## Convexity is the important limitation of hull()

The central geometric fact about `hull()` is that its result is always
convex.

For a convex profile, this is often exactly what is wanted. Connecting nested
rounded rectangles or other convex layers gives a predictable transition.

For a concave profile, a global hull cannot preserve a notch, opening or
re-entrant corner. It bridges across it.

Conceptually:

~~~text
convex input               concave input

  ______                     ______
 /      \                   |      |
|        |                  |   ___|
 \______/                   |__|

hull preserves            hull bridges across
the intended boundary     the missing region
~~~

This does not mean `hull()` cannot be used in a model containing concave
geometry. It means the problem usually needs to be **decomposed**:

- hull a simpler convex outside envelope and clip it afterward;
- hull a convex opening and subtract it;
- use several local hulls;
- or use explicit cutters for the local feature.

## Decompose a shell into simpler problems

A hollow or L-shaped final part may be geometrically complicated while its
construction can still consist of simple operations.

A common approach is:

~~~text
1. construct a simple outer body
2. construct a simple inner void
3. subtract the void
4. add or subtract local details
5. trim to final bounds if needed
~~~

The important point is that the final shell does not need to be generated in
one operation.

This is often easier to understand, test and maintain than asking one global
operation to reproduce every concave boundary at once.

## A practical decision sequence

When adding a feature, use this order of questions:

1. **What physical change do I want?**
   Material added/kept, material removed, or a final boundary?
2. **Which shape is easiest to describe?**
   The desired remaining material, the unwanted material, or a bounding
   envelope?
3. **Is the shape convex?**
   If not, a global `hull()` may bridge regions that must stay open.
4. **Can the problem be split into simpler local or convex pieces?**
5. **Only then choose the operator.**

A compact mapping is:

~~~text
easy to describe what remains  -> keep geometry
easy to describe what is lost  -> cutter + difference()
easy to describe final limits  -> clip + intersection()
need transition between shapes -> hull(), then use that hull in one of
                                  the roles above
~~~

## Chamfers as an example

A chamfer illustrates why the roles matter.

### Outside edge: constructive version

If a smaller end profile and a normal profile are easy to define, a hull can
directly build the chamfered outside body.

### Inside edge: subtractive version

If an enlarged opening and its normal opening are easy to define, their hull
can form a tapered cutter that is subtracted.

### Final end position: clipping version

If profiles are deliberately extended so the chamfer can be constructed
cleanly, a later intersection can trim them to the exact final dimensions.

These are three different jobs:

| Job | Geometry role |
| --- | --- |
| create the outside slope | keep geometry |
| remove the inside slope | cut geometry |
| impose the exact end plane | clip / trim geometry |

They should not be presented as one combined "chamfer method".

## Prefer the simplest faithful construction

Two implementations can produce nearly identical solids while having very
different cognitive cost.

Prefer the construction that:

- matches the physical intent;
- is easy to explain with intermediate geometry;
- handles all required boundaries;
- has fewer special cases;
- remains stable across the supported parameter range;
- can be regression-tested.

Do not replace a simple subtractive construction merely to make every feature
use `hull()`. Likewise, do not avoid `hull()` when it expresses a transition
more clearly than hand-built wedges.

The modelling method should follow the geometry, not stylistic consistency.

## Related examples

The archive contains small examples that demonstrate these roles independently:

- [Rounded rectangular tube](../examples/rounded-rectangular-tube/v0.1/) —
  outside chamfer as keep geometry, inside chamfer as a cutting volume.
- [Rounded L bracket](../examples/rounded-l-bracket/v0.1/) —
  the same roles plus deliberately overlong profiles followed by a final
  trimming `intersection()`.

The examples are intentionally self-contained. This page provides the shared
vocabulary for reasoning about them and about larger models in the archive.
