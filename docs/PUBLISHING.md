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

## Pages deployment limitation

The repository's Pages source has historically been the `gh-pages` branch.
**GitHub does not trigger a new Pages build for branch commits made using
the default GitHub Actions `GITHUB_TOKEN`.** The CI push alone therefore
does not confirm a refreshed public site.

For unattended publication, Pages must instead be configured to deploy from
**GitHub Actions**, using `actions/upload-pages-artifact` and
`actions/deploy-pages`. Until that migration is completed, an externally
authenticated update to `gh-pages` can trigger the normal branch-based
Pages build. We must verify the resulting Pages deployment before claiming
the public documentation is live.

See [GitHub's Pages publishing configuration](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).
