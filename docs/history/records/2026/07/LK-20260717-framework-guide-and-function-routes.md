# Framework guides and function reference keep distinct routes

```labkit-change
schema: 2
id: LK-20260717-framework-guide-and-function-routes
date: 2026-07-17
sequence: 134
type: fix
compatibility: compatible
scope: Documentation information architecture
```

## Context

An initial Framework documentation alignment also classified individual
`labkit.ui.*` and `labkit.contract.*` API pages as Framework pages. Entering
those pages from the global Functions index then changed the active top-level
area, which mixed conceptual ownership with page type and made return paths
hard to predict.

## Decision and rationale

Keep conceptual and workflow guides under Framework. Keep every exact MATLAB
function contract under Functions. Visible API group labels still explain that
`labkit.ui` is the Framework implementation, but the top navigation remains
stable while browsing function reference pages.

## Changes

- Moved the canonical compatibility guide to `framework/contracts.html`.
- Kept a tracked legacy page at `libraries/contracts/index.html` that links to
  the new guide and the Functions reference.
- Restored Functions ownership for all individual UI and contract API pages.
- Updated framework, library, and regression-test links to the canonical
  guide.

## User and data impact

Readers now follow one predictable route for Framework guides and another for
exact function syntax. Existing contract-guide bookmarks still reach a
compatibility page. MATLAB code and scientific data are unchanged.

## Compatibility and migration

The old guide URL remains as a compatibility landing page. Public MATLAB
symbols remain unchanged.

## Validation

Renderer regression verifies the Framework guide route, legacy landing page,
and Functions-active runtime API page. `docsCheck` verifies the complete site.

## Evidence

The generated Framework landing page links directly to
`framework/contracts.html`, while `labkit.ui.runtime.launch` highlights
Functions and labels its sibling group Framework Runtime.

## Known limitations and follow-up

The legacy page is a visible handoff rather than an HTTP redirect because the
tracked static-site renderer does not currently emit redirect responses.
