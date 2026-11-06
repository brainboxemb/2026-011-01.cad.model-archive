# Documentation publication — GitHub Pages

## Choice: Pages rather than Wiki

NopSCADlib generates a combination of HTML, Markdown, image previews,
STLs and BOMs. A static GitHub Pages site preserves these files and their
relative links better than manually copying them into GitHub Wiki.

## Branch already available

The **`gh-pages` branch exists** and currently contains only:

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

## Enable the site manually

In GitHub, open the model archive repository:

1. **Settings → Pages**
2. Under **Build and deployment**, select **Deploy from a branch**.
3. Select **`gh-pages`** and **`/(root)`**.
4. Select **Save**.

GitHub should then publish the holding page at
`https://brainboxemb.github.io/2026-011-01.cad.model-archive/`.
This URL is the expected destination, not a claim that the Pages site
is already active.

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

## Publication automation (later)

We do **not** yet publish generated documentation from the CI smoke workflow.
Its output is a short-lived CI artifact. For now the priority is **opening
models in the local Windows OpenSCAD GUI**.

When automated publication is desired, decide explicitly how Pages deploys:
a push with the default `GITHUB_TOKEN` does **not** trigger a build of a
branch-based Pages site. A supported `actions/upload-pages-artifact` +
`actions/deploy-pages` workflow with Pages set to **GitHub Actions** is an
alternative. Do not silently mix these methods.

See [GitHub Pages publishing sources](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).
