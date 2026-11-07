#!/usr/bin/env python3
"""Update the *main* Pages homepage with links to active PR/branch previews.

The homepage itself stays as published: on a PR build only the region
between the generated markers is modified. Each preview is listed only
while its directory exists; removing a closed PR removes its link.
"""
from __future__ import annotations

import html
import json
from pathlib import Path
import re
import sys

BEGIN = "<!-- BEGIN GENERATED BRANCH PREVIEWS -->"
END = "<!-- END GENERATED BRANCH PREVIEWS -->"
REPO_URL = "https://github.com/brainboxemb/2026-011-01.cad.model-archive"
PREVIEW_RE = re.compile(r"pr-([0-9]+)$")


def preview_links(pages: Path) -> str:
    entries: list[tuple[int, str]] = []
    for directory in (pages / "previews").glob("pr-*"):
        match = PREVIEW_RE.fullmatch(directory.name)
        if not match or not (directory / "index.html").is_file():
            continue
        number = int(match.group(1))
        branch = ""
        metadata = directory / "preview.json"
        if metadata.is_file():
            try:
                info = json.loads(metadata.read_text(encoding="utf-8"))
                if info.get("pr") == number and isinstance(info.get("branch"), str):
                    branch = info["branch"][:200]
            except (ValueError, OSError):
                pass  # A malformed metadata file must not break the homepage.
        title = f"PR #{number}"
        if branch:
            title += f" — {branch}"
        safe_title = html.escape(title, quote=True)
        entries.append(
            (number,
             f'    <li><a href="previews/pr-{number}/">{safe_title}</a> '
             f'(<a href="{REPO_URL}/pull/{number}">pull request</a>)</li>')
        )

    # Newest PR first, so the active preview is visible immediately.
    items = "\n".join(item for _, item in sorted(entries, reverse=True))
    if not items:
        items = "    <li>No active branch previews.</li>"

    return (
        f"{BEGIN}\n"
        '  <section id="branch-previews" aria-label="Branch previews">\n'
        '    <h2>Branch previews</h2>\n'
        '    <p>Preview builds for open pull requests. These are not yet '
        'part of the published model archive.</p>\n'
        f'    <ul>\n{items}\n    </ul>\n'
        '  </section>\n'
        f"{END}"
    )


def update_homepage(pages: Path) -> None:
    homepage = pages / "index.html"
    content = homepage.read_text(encoding="utf-8")
    section = preview_links(pages)
    if BEGIN in content and END in content:
        content = re.sub(
            re.escape(BEGIN) + r".*?" + re.escape(END),
            lambda _: section, content, flags=re.DOTALL
        )
    else:
        # Older Pages sites have no placeholder. Insert before Models,
        # preserving the published homepage when a PR is built.
        marker = "<h2>Models</h2>"
        if marker not in content:
            raise ValueError("Missing homepage Models heading")
        content = content.replace(marker, section + "\n  " + marker, 1)
    homepage.write_text(content, encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: update-preview-index.py <gh-pages-worktree>")
    update_homepage(Path(sys.argv[1]))
