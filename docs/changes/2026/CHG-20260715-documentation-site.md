# Searchable MATLAB-generated documentation site

```labkit-change
id: CHG-20260715-documentation-site
date: 2026-07-15
type: feat
compatibility: compatible
component: labkit_launcher | 1.4.0 -> 1.5.0
```

## Why

LabKit documentation was distributed across large Markdown pages without a generated site, global search, or one-to-one public MATLAB reference pages. Users needed browsable offline documentation, while developers needed the reference site to stay synchronized with public MATLAB help without adding a third-party runtime. Launcher maintenance actions were also difficult to distinguish from normal App use.

## What changed

LabKit added a Base MATLAB static compiler, responsive navigation, offline-safe search, generated public API pages, deterministic tree comparison, and a launcher action for rebuilding local documentation. Private helpers remained outside public reference.

## Impact

Users could search manuals and public functions, move between related APIs, and rebuild the same local site from a source checkout. Markdown and public help became the maintained sources, while generated `site/` output became disposable. The repository-owned Base MATLAB compiler became the durable architecture choice.

## Compatibility and limits

The feature was compatible and did not change App data, calculations, projects, or exports. Source-only packages without documentation tools could not generate a local site; their launcher action reported that boundary. The first site retained long mixed-purpose manuals and transitional navigation, which later changes addressed.
