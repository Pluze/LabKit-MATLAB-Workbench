# Documentation paths become navigation ownership

```labkit-change
id: CHG-20260719-path-derived-documentation
date: 2026-07-19
type: refactor
compatibility: compatible
component: labkit_launcher | 1.5.1 -> 1.5.2
```

## Why

Navigation ownership was duplicated across Markdown, site configuration, catalog files, and generated output. Adding or moving a page required several coordinated edits that could disagree. Authors needed one discoverable source of navigation truth and a safe way to update current relative links.

## What changed

The renderer derived narrative navigation from `docs/`, discovered Apps from launcher metadata, discovered API pages from complete MATLAB help, removed the duplicated catalogs, and added uniquely resolved link maintenance.

## Impact

The local site and launcher actions remained available. Authors placed Markdown in its owning directory instead of editing parallel catalogs; ambiguous link movement required an explicit author decision.

## Compatibility and limits

Current source links were updated, and retired routes were removed rather than kept as redirects. Scientific behavior and laboratory data were unchanged. Path inference reduced duplicate catalogs but made one filesystem location own identity, route, audience, type, and navigation simultaneously; that coupling motivated the typed reader-intent model.
