# Documentation publication — GitHub Pages

## Choice: Pages rather than Wiki

NopSCADlib generates a combination of HTML, Markdown, image previews,
STLs and BOMs. A static GitHub Pages site preserves these files and their
relative links better than manually copying them into GitHub Wiki.

## Branch already available

The **`gh-pages` branch exists**. Before the first documentation publication it contains:

```text
gh-pages/
├── .nojekyll
└── index.html        A basic holding page; no models published yet
```

The file tree is separate from the model source on `main`. **Technical
clarification:** the current branch was initialized from `main` and its
contents replaced with a clean site tree; it is not a parentless *orphan*
Git commit. That distinction does not affect GitHub Pages publishing.
We can convert it to a true orphan later if history isolation is worth
doing, but it is not needed to enable Pages.

## Current Pages state

GitHub automatically started the **Pages build and deployment** workflow
after the `gh-pages` branch was created. That initial deployment completed
successfully. No manual Pages-setting change was needed.

The placeholder is intended to be available at
`https://brainboxemb.github.io/2026-011-01.cad.model-archive/`.
No model documentation is published yet.

## Intended model pages

```text
gh-pages/
├── .nojekyll
├── index.html                       Model index
└── models/
    └── tube-clip/
        ├── index.html               Links to retained versions
        ├── v0.1/
        │   ├── index.html           Generated NopSCADlib readme.html
        │   ├── printme.html
        │   ├── assemblies/
        │   ├── stls/
        │   └── bom/
        └── v0.2/
            └── ...
```

Authoritative model sources and `dependencies.repos` remain on `main`;
generated content lives on `gh-pages`, where old versions should be
preserved instead of overwritten.

## Publishing the example documentation

On pushes to `main`, the NopSCADlib workflow uses the **centrally built**
`ghcr.io/brainboxemb/scad-toolchain-drawing` image to generate the example
spacer's documentation. It copies the resulting HTML, BOM, STL and PNG
files to `gh-pages/examples/spacer/v0.1/` and updates the site index.
This has not yet been deployed from the pending workflow changes.

The normal Windows workflow remains **opening models in the local OpenSCAD GUI**;
no documentation generator or Docker is needed on Windows.

When automated publication is desired, decide explicitly how Pages deploys:
a push with the default `GITHUB_TOKEN` does **not** trigger a build of a
branch-based Pages site. Thus an output commit on `gh-pages` alone does not
prove that the public site has refreshed. A manual externally authenticated
commit or changing Pages to GitHub Actions deployment is required to publish
that commit. This remains to be finalized for unattended publishing. A supported `actions/upload-pages-artifact` +
`actions/deploy-pages` workflow with Pages set to **GitHub Actions** is an
alternative. Do not silently mix these methods.

See [GitHub Pages publishing sources](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).
