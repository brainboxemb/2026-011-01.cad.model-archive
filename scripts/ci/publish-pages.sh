#!/usr/bin/env bash
# Publish the generated site either at the site root (main) or under a
# self-contained PR preview prefix. Runs after successful doc generation.
set -euo pipefail

cd "$(dirname "$0")/../.."
git fetch origin gh-pages
worktree="$(mktemp -d)"
cleanup() {
  git worktree remove --force "$worktree" 2>/dev/null || true
  rmdir "$worktree" 2>/dev/null || true
}
trap cleanup EXIT
git worktree add --detach "$worktree" origin/gh-pages

# Use only CI-controlled paths; never accept arbitrary destination paths.
preview="${PAGES_PREVIEW_ROOT:-}"
if [[ -n "$preview" && ! "$preview" =~ ^previews/pr-[0-9]+$ ]]; then
  echo "Invalid preview destination: $preview" >&2
  exit 1
fi
target="$worktree"
if [[ -n "$preview" ]]; then
  target="$worktree/$preview"
fi

# Closing a PR removes only its preview. Do not touch published main pages.
if [[ "${PAGES_PREVIEW_REMOVE:-0}" == "1" ]]; then
  [[ -n "$preview" ]] || { echo "Refusing to remove the site root" >&2; exit 1; }
  rm -rf "$target"
else
  mkdir -p "$target"
  for version in examples/spacer/v0.1 models/corner_bracket/v0.1; do
    mkdir -p "$target/$version"
    cat site/model-header.html "$version/readme.html" > "$target/$version/index.html"
    printf '\n</main></body></html>\n' >> "$target/$version/index.html"
    cp "$version/readme.md" "$target/$version/readme.md"
    cp "$version/printme.html" "$target/$version/printme.html"
    cp -a "$version/stls" "$version/assemblies" "$version/bom" "$version/scad" "$target/$version/"
  done

  bracket="models/corner_bracket/v0.1"
  cp -a "$bracket/design" "$target/$bracket/"
  cp -a "$bracket/figures" "$target/$bracket/"
  mkdir -p "$target/$bracket/docs"
  cp "$bracket/docs/"*.md "$bracket/docs/documentation.scad" "$target/$bracket/docs/"
  for page in mounting-options hull-guide polygon-guide chamfer-guide ef-hull-experiment; do
    cat site/guide-header.html "$bracket/docs/$page.html" > "$target/$bracket/docs/$page.html"
    printf '\n</main></body></html>\n' >> "$target/$bracket/docs/$page.html"
    test -s "$target/$bracket/docs/$page.html"
  done
  cp site/index.html site/site.css "$target/"
  if [[ -n "$preview" ]]; then
    # Save the branch identity for the public landing page. This is a PR
    # number, not an arbitrary path. The Python index builder HTML-escapes
    # the displayed branch name.
    PREVIEW_META_PATH="$target/preview.json" PREVIEW_PATH="$preview" \
      python3 - <<'PY'
import json
import os
from pathlib import Path
number = int(os.environ["PREVIEW_PATH"].split("pr-")[1])
branch = os.environ.get("PAGES_PREVIEW_BRANCH", "")
Path(os.environ["PREVIEW_META_PATH"]).write_text(
    json.dumps({"pr": number, "branch": branch}, indent=2) + "\n",
    encoding="utf-8",
)
PY
  fi
  touch "$worktree/.nojekyll"
fi

# Always update the ROOT homepage, even when publishing/removing a PR
# preview. Never replace the root homepage template from a PR branch:
# the generator updates only the preview navigation region.
python3 scripts/ci/update-preview-index.py "$worktree"

git -C "$worktree" config user.name "github-actions[bot]"
git -C "$worktree" config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git -C "$worktree" add -A
if git -C "$worktree" diff --cached --quiet; then
  echo "Pages content unchanged"
else
  message="Publish model documentation"
  if [[ -n "$preview" ]]; then
    message="Update $preview documentation preview"
    if [[ "${PAGES_PREVIEW_REMOVE:-0}" == "1" ]]; then
      message="Remove closed $preview documentation preview"
    fi
  fi
  git -C "$worktree" commit -m "$message from ${GITHUB_SHA:-manual}"
  git -C "$worktree" push origin HEAD:gh-pages
fi
