# Corner bracket

Parametric, printable outside-corner bracket for joining 10 mm plywood
panels. The design includes two recessed M4 captive-nut pockets, access
windows in the wood-facing surfaces and two press-in access plugs.

**Status:** Work in progress; unverified print tolerances and joint strength.

## Versions

- **[v0.1](v0.1/)** — Imported source with English comments and a separate
  six-step geometry walkthrough.

## Files

- [Parametric bracket source](v0.1/scad/corner_bracket.scad) — OpenSCAD
  Customizer controls dimensions, inspection section, bracket/plug output.
- [Design walkthrough](v0.1/scad/design.scad) — Six selectable construction
  stages, based on the same geometry.
- [Documentation generator entry point](v0.1/scad/documentation.scad) —
  NopSCADlib STL and assembly declarations and a rendered design narrative.
- [Design notes](v0.1/README.md) — Manufacturing and assembly details.

Use `bootstrap.ps1` at the archive root to retrieve pinned NopSCADlib.
Opening the parametric source directly does not require NopSCADlib; generating
the documentation does.
