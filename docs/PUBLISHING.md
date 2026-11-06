# Documentation publication — planned, not enabled

## Decision: GitHub Pages, not the GitHub Wiki

The **GitHub Wiki is not the publication target**. NopSCADlib generates
Markdown, HTML, diagrams, PNG previews, STL exports and BOMs together. Those
files are better published as a versioned static site than copied into a Wiki.

**Target:** GitHub Pages from a clean, **orphan `gh-pages` branch**, with
`.nojekyll` in its root. This keeps generated content completely separate from
the OpenSCAD sources and their Git history on `main`.

Intended site layout (example, *not deployed*):

```text
gh-pages/ (orphan: no shared ancestor with main)
├── .nojekyll
├── index.html                      Model index / catalog
└── models/
    └── spacer/
        ├── index.html              Links to version pages
        ├── v0.1/
        │   ├── index.html          NopSCADlib's generated readme.html
        │   ├── printme.html
        │   ├── assemblies/
        │   ├── stls/
        │   └── bom/
        └── v0.2/
            └── ...
```

**Authoring vs output**

- `main`: hand-edited `.scad`, model descriptions, `dependencies.repos`,
  Windows opening workflow and CI definitions.
- `gh-pages`: **only generated output**, grouped per model/version.
- NopSCADlib's version-local `readme.html` can become the published
  `index.html` without rewriting the entire document, while all relative image
  and STL paths remain in the same version folder.
- Previous published versions stay available; avoid overwriting v0.1 when
  preparing v0.2.

## Status and future deployment

There is **no `gh-pages` branch, GitHub Pages setting, or publishing workflow
yet**. Documentation generation is currently only exercised as a CI smoke
test and published as a short-lived workflow artifact. Manual Windows work
starts with **opening and editing models**, not documentation generation.

When publication is wanted, first validate the generated HTML and assets,
then create the orphan branch and configure GitHub **Settings > Pages >
Deploy from a branch > `gh-pages` > /(root)**.

**GitHub Actions caveat:** pushing commits to `gh-pages` using the default
`GITHUB_TOKEN` does not itself trigger a Pages build. Before automating
publication, choose a supported deployment path (for example
`actions/upload-pages-artifact` + `actions/deploy-pages` with GitHub Pages
configured for **GitHub Actions**) rather than silently relying on that push.
This does not require a new Python documentation framework.

Reference:
[GitHub Pages publishing sources](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).
