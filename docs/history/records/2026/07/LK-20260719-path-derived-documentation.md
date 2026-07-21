# Documentation structure becomes the navigation contract

```labkit-change
id: LK-20260719-path-derived-documentation
date: 2026-07-19
sequence: 136
type: refactor
compatibility: compatible
component: `labkit_launcher` | `1.5.1 -> 1.5.2`
scope: Documentation renderer
scope: Documentation maintenance
```

## Context

The local HTML site duplicated documentation ownership across Markdown files,
`site.json`, two catalog JSON files, and generated output. Moving or adding a
page therefore required several coordinated edits. Markdown links also embedded
many relative paths without a repository-owned way to repair links after a
move.

## Decision and rationale

Treat the `docs/` directory structure as the narrative navigation contract.
Discover public Apps from `labkit_launcher("list")`, associate each App with
its unique path-conventional manual, and discover public API pages from complete
MATLAB help contracts. Keep ordinary relative Markdown links so source pages
remain useful in GitHub and add a checker that can repair a broken link only
when its destination is unambiguous.

The generated `site/` remains the offline and local HTML product. It is still
produced exclusively by the repository renderer.

## Changes

- Removed `docs/site.json` and the App and API catalog JSON files.
- Reorganized development and framework guides into path-owned navigation
  groups and moved the API landing page to `docs/reference/README.md`.
- Made the renderer discover Markdown pages, public Apps, and complete public
  MATLAB help without duplicated registries.
- Added `maintainLabKitDocLinks` for checking and uniquely repairing relative
  Markdown links after file moves.
- Changed launcher documentation lookup to derive the selected App manual and
  generated HTML path from App discovery and documentation structure.
- Removed obsolete compatibility redirect pages instead of preserving legacy
  documentation routes.

## User and data impact

Local HTML documentation and launcher documentation actions remain available.
Contributors add or move a page by placing Markdown in the intended directory
and running the link maintainer and renderer; no navigation catalog needs a
matching edit. Scientific behavior and project data are unchanged.

## Compatibility and migration

Existing current documentation links are rewritten to their new relative
paths. Old generated documentation routes are intentionally retired and are
not maintained as redirect pages. Rebuild `site/` after updating a checkout.

## Validation

Focused documentation contract and renderer regression tests cover discovery,
navigation, link repair, public API help, and launcher documentation lookup.
The documentation checker validates the generated site after a clean local
render.

## Evidence

- [Documentation Build Tools](../../../../development/tools/documentation.md)
- [Maintaining LabKit Documentation](../../../../development/maintain-and-release/documentation.md)
- [LabKit Launcher](../../../../apps/labkit-core/launcher/README.md)
- [API Reference](../../../../reference/README.md)

## Known limitations and follow-up

Automatic link repair deliberately refuses ambiguous destinations. Authors must
resolve those cases explicitly so the checker never guesses between pages with
the same filename or title.
