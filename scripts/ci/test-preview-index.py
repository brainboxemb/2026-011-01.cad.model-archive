#!/usr/bin/env python3
"""Unit tests for the public homepage's PR-preview navigation."""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("update-preview-index.py")
spec = importlib.util.spec_from_file_location("update_preview_index", SCRIPT)
assert spec and spec.loader
indexer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(indexer)


class PreviewIndexTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / "index.html").write_text(
            "<html><body><h1>OpenSCAD Model Archive</h1>\n"
            '<h2>Models</h2><p id="main-model">Production model</p>\n'
            "</body></html>", encoding="utf-8"
        )

    def preview(self, number, branch):
        directory = self.root / "previews" / f"pr-{number}"
        directory.mkdir(parents=True)
        (directory / "index.html").write_text("<html>preview</html>")
        (directory / "preview.json").write_text(
            json.dumps({"pr": number, "branch": branch}), encoding="utf-8"
        )
        return directory

    def html(self):
        return (self.root / "index.html").read_text(encoding="utf-8")

    def test_generated_links_and_branch_names(self):
        self.preview(11, "docs/clarify-hulls")
        self.preview(12, 'fix/<svg onload="bad">')
        indexer.update_homepage(self.root)
        result = self.html()
        self.assertIn('href="previews/pr-11/"', result)
        self.assertIn("PR #11 — docs/clarify-hulls", result)
        self.assertIn('href="previews/pr-12/"', result)
        self.assertIn("&lt;svg onload=&quot;bad&quot;&gt;", result)
        self.assertNotIn('<svg onload="bad">', result)
        self.assertLess(result.index("PR #12"), result.index("PR #11"))
        self.assertIn('id="main-model"', result)

    def test_republish_is_idempotent_and_removal_updates_homepage(self):
        directory = self.preview(11, "docs/example")
        indexer.update_homepage(self.root)
        first = self.html()
        indexer.update_homepage(self.root)
        self.assertEqual(first, self.html())
        shutil.rmtree(directory)
        indexer.update_homepage(self.root)
        self.assertNotIn('href="previews/pr-11/"', self.html())
        self.assertIn("No active branch previews", self.html())
        self.assertIn('id="main-model"', self.html())

    def test_only_directories_with_generated_pages_are_listed(self):
        self.preview(5, "feature/example")
        (self.root / "previews" / "pr-5" / "index.html").unlink()
        (self.root / "previews" / "pr-not-a-number").mkdir(parents=True)
        indexer.update_homepage(self.root)
        self.assertNotIn('href="previews/pr-5/"', self.html())
        self.assertIn("No active branch previews", self.html())

    def test_older_preview_without_metadata_still_works(self):
        directory = self.preview(20, "old/branch")
        (directory / "preview.json").unlink()
        indexer.update_homepage(self.root)
        self.assertIn('href="previews/pr-20/"', self.html())
        self.assertNotIn("old/branch", self.html())


if __name__ == "__main__":
    unittest.main()
