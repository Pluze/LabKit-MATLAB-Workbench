#!/usr/bin/env python3
"""Regression tests for GitHub Markdown paragraph normalization."""

import importlib.util
import pathlib
import unittest


SCRIPT = pathlib.Path(__file__).with_name("normalize_github_markdown.py")
SPEC = importlib.util.spec_from_file_location("normalize_github_markdown", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class NormalizeGitHubMarkdownTest(unittest.TestCase):
    def test_repository_github_templates_are_normalized(self):
        root = SCRIPT.parents[2]
        paths = (
            root / ".github" / "PULL_REQUEST_TEMPLATE.md",
            root / ".github" / "RELEASE_NOTES_TEMPLATE.md",
            root / ".github" / "SUPPORT.md",
            root / ".github" / "ISSUE_TEMPLATE" / "bug_report.md",
            root / ".github" / "ISSUE_TEMPLATE" / "workflow_request.md",
        )
        for path in paths:
            with self.subTest(path=path):
                source = path.read_text(encoding="utf-8")
                self.assertEqual(MODULE.normalize_markdown(source), source)

    def test_joins_paragraphs_and_list_continuations(self):
        source = (
            "## Why\n\nA wrapped prose\nparagraph.\n\n"
            "- A wrapped list\n  item.\n- Next item.\n"
        )
        self.assertEqual(
            MODULE.normalize_markdown(source),
            "## Why\n\nA wrapped prose paragraph.\n\n"
            "- A wrapped list item.\n- Next item.\n",
        )

    def test_preserves_fences_tables_links_and_explicit_breaks(self):
        source = (
            "```text\nfirst\nsecond\n```\n\n"
            "| A | B |\n|---|---|\n| 1 | 2 |\n\n"
            "[first](https://example.com/1)\n"
            "[second](https://example.com/2)\n\n"
            "Keep this break.  \nNext line.\n"
        )
        self.assertEqual(MODULE.normalize_markdown(source), source)

    def test_preserves_nested_lists_and_checkboxes(self):
        source = (
            "- Parent\n"
            "  - Nested item\n"
            "    - Deeper item\n"
            "- [ ] One checkbox\n  with detail.\n"
        )
        self.assertEqual(
            MODULE.normalize_markdown(source),
            "- Parent\n  - Nested item\n    - Deeper item\n"
            "- [ ] One checkbox with detail.\n",
        )

    def test_preserves_issue_frontmatter_and_empty_numbered_items(self):
        source = (
            "---\nname: Bug report\ntitle: '[Bug]: '\n---\n\n"
            "## Steps\n\n1.\n2.\n3.\n"
        )
        self.assertEqual(MODULE.normalize_markdown(source), source)

    def test_normalization_is_idempotent(self):
        normalized = MODULE.normalize_markdown("Wrapped\nparagraph.\n")
        self.assertEqual(normalized, "Wrapped paragraph.\n")
        self.assertEqual(MODULE.normalize_markdown(normalized), normalized)


if __name__ == "__main__":
    unittest.main()
