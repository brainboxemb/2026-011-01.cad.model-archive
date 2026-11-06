# Archived models

Small standalone models go in a named directory, with a human-written
`README.md` describing the model and, if relevant, linking its versions.

- Versioned: `models/<name>/v0.1/scad/main.scad`, `v0.2/scad/main.scad`, etc.
- No version numbering: `models/<name>/source/scad/main.scad`.

NopSCADlib writes generated lowercase `readme.md` beside each project's
`scad/` directory. Keeping the `source/` (or `vX.Y/`) directory separate from
the model overview avoids a case-insensitive filename clash on Windows.

No finished models have been archived yet. Start with the
[spacer example](../examples/spacer/v0.1/scad/spacer.scad)
and the [Windows workflow](../docs/WORKFLOW.md).
