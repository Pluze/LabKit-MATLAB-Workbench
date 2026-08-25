# Framework guides and function reference keep distinct routes

```labkit-change
id: CHG-20260717-framework-guide-and-function-routes
date: 2026-07-17
type: fix
compatibility: compatible
component: repository
```

## Why

An initial Framework documentation alignment also classified individual `labkit.ui.*` and `labkit.contract.*` API pages as Framework pages. Entering those pages from the global Functions index then changed the active top-level area, which mixed conceptual ownership with page type and made return paths hard to predict.

### Accepted choice

Keep conceptual and workflow guides under Framework. Keep every exact MATLAB function contract under Functions. Visible API group labels still explain that `labkit.ui` is the Framework implementation, but the top navigation remains stable while browsing function reference pages.

## What changed

- Moved the canonical compatibility guide to `framework/contracts.html`.
- Kept a tracked legacy page at `libraries/contracts/index.html` that links to the new guide and the Functions reference.
- Restored Functions ownership for all individual UI and contract API pages.
- Updated framework, library, and regression-test links to the canonical guide.

## Impact

Readers now follow one predictable route for Framework guides and another for exact function syntax. Existing contract-guide bookmarks still reach a compatibility page. MATLAB code and scientific data are unchanged.

## Compatibility and limits

The old guide URL remains as a compatibility landing page. Public MATLAB symbols remain unchanged.

### Remaining limits

The legacy page is a visible handoff rather than an HTTP redirect because the tracked static-site renderer does not currently emit redirect responses.
