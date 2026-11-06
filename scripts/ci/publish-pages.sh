#!/usr/bin/env bash
# Assemble the public GitHub Pages site using templates in site/.
# Runs only on pushes to main, after generation and validation succeeded.
set -euo pipefail

cd "$(dirname "$0")/../.."
git fetch origin gh-pages
site="$(mktemp -d)"
cleanup() {
  git worktree remove --force "$site" 2>/dev/null || true
  rmdir "$site" 2>/dev/null || true
}
trap cleanup EXIT
git worktree add --detach "$site" origin/gh-pages

for version in examples/spacer/v0.1 models/corner_bracket/v0.1; do
  mkdir -p "$site/$version"
  cat site/model-header.html "$version/readme.html" > "$site/$version/index.html"
  printf '\n</main></body></html>\n' >> "$site/$version/index.html"
  cp "$version/readme.md" "$site/$version/readme.md"
  cp "$version/printme.html" "$site/$version/printme.html"
  cp -a "$version/stls" "$version/assemblies" "$version/bom" "$version/scad" "$site/$version/"
done

cp -a models/corner_bracket/v0.1/design "$site/models/corner_bracket/v0.1/"
cp site/index.html site/site.css "$site/"
touch "$site/.nojekyll"

git -C "$site" config user.name "github-actions[bot]"
git -C "$site" config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git -C "$site" add -A
if git -C "$site" diff --cached --quiet; then
  echo "Pages content unchanged"
else
  git -C "$site" commit -m "Publish generated model documentation from ${GITHUB_SHA:0:12}"
  git -C "$site" push origin HEAD:gh-pages
fi
