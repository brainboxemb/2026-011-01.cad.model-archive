# Generated documentation and GitHub Pages

The model archive publishes NopSCADlib-generated HTML, STL, BOM, and PNG
design/assembly images to the `gh-pages` branch.

## Generator

GitHub Actions runs the upstream NopSCADlib `make_all.py` generator inside
the central `ghcr.io/brainboxemb/scad-toolchain-drawing` image (defined in
[`docker.scad-toolchain`](https://github.com/brainboxemb/docker.scad-toolchain)).
There is **no repository-local Dockerfile**.

For each production model, NopSCADlib generates:
- `readme.html`, `readme.md`, and print-friendly `printme.html`;
- printed-part STL files and previews under `stls/`;
- assembly views under `assemblies/`;
- a bill of materials under `bom/`.

The corner bracket adds six sequential, source-generated images under
`design/`. They come from `models/corner_bracket/v0.1/scad/design.scad`;
this file calls the same geometry modules as the parametric model.

These files are created **only in GitHub Actions**. Generation on local
Windows workstations is not supported.

## Publication paths

On pushes to `main`, the CI workflow copies the generated files into a
commit on the `gh-pages` branch:

```text
gh-pages/
├── index.html
├── examples/spacer/v0.1/
│   ├── index.html
│   ├── printme.html
│   ├── stls/
│   ├── assemblies/
│   └── bom/
└── models/corner_bracket/v0.1/
    ├── index.html
    ├── printme.html
    ├── design/
    ├── stls/
    ├── assemblies/
    └── bom/
```

NopSCADlib `readme.html` is renamed `index.html` for the website. Its
relative PNG and STL links remain valid.

## Pages deployment

GitHub Pages is configured to publish the `gh-pages` branch. On
6 November 2026, the documentation workflow published the generated spacer
and corner bracket files to this branch and the Pages build/deployment
completed successfully (GitHub Actions run
[42212520812](https://github.com/brainboxemb/2026-011-01.cad.model-archive/actions/runs/42212520812)).

On future updates, verify that the Pages build/deployment workflow completed
successfully before treating the public site as current.
