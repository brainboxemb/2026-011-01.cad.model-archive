# Static documentation site

The web page templates are stored here, **not in the GitHub Actions workflow**.

- `index.html`: model archive homepage.
- `model-header.html`: reusable HTML wrapper for generated NopSCADlib pages.
- `site.css`: styles for both the homepage and generated documentation.

GitHub Actions calls `scripts/ci/generate-docs.sh` and
`scripts/ci/publish-pages.sh`. The latter copies these files and the
NopSCADlib-generated HTML, images, STLs, and BOMs to `gh-pages`.

The complete site is generated in CI, not on Windows workstations.
