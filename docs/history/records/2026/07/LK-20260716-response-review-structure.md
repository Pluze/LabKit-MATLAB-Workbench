# Response Review Stats uses one project contract

```labkit-change
schema: 2
id: LK-20260716-response-review-structure
date: 2026-07-16
sequence: 105
type: refactor
compatibility: compatible
component: `labkit_ResponseReviewStats_app` | `1.4.2 -> 1.4.3`
scope: Neurophysiology
scope: App structure
```

## Context

Response Review Stats kept project creation, validation, its one source-schema
migration, and session reconstruction in four generic lifecycle files. Session
and presentation code also read the Runtime's nested source path directly, and
the reset action depended on the generic lifecycle package.

## Decision and rationale

Use the standard compact Runtime V2 structure: one definition, one project
contract, and one root session factory. Metric alignment, measurement,
summaries, source parsing, exports, and presentation already had clear owners
and remain unchanged.

## Changes

- Consolidated product metadata, version, requirements, layout, actions,
  presentation, renderer, and debug capability in `definition.m`.
- Concentrated project creation, validation, and the version-1 source upgrade
  in `projectSpec.m`.
- Moved transient metric/alignment reconstruction to root `createSession.m`
  and reused it for the reset action.
- Replaced direct portable-reference reads with semantic `sourcePaths` lookup.
- Removed the generic lifecycle package and separate requirement/version files.

## User and developer impact

Analysis JSON and segment CSV loading, automatic window recomputation, aligned
preview, metric summaries, reset, output-folder choice, CSV export, and result
manifest behavior are unchanged. Developers now see the entire durable schema
history through one entry instead of four lifecycle files.

## Compatibility and migration

Durable schema version 2 is unchanged. Version-1 projects still move their
singular source to the canonical source collection before validation and the
next save.

## Validation

Focused tests cover source migration, segment parsing, time-grid alignment,
measurement, pair-group summaries, and default-grid selection. The hidden GUI
workflow loads representative metrics, presents them, and exports the CSV and
manifest through real Runtime callbacks.

## Evidence

- [Response Review And Stats](../../../../apps/neurophysiology/response-review-stats/README.md)
- [Runtime and Lifecycle](../../../../framework/runtime.md)
- [Nerve Response Analysis](../../../../apps/neurophysiology/nerve-response-analysis/README.md)

## Known limitations and follow-up

Automated checks do not validate biological interpretation of a chosen
baseline/noise window. The larger RHS Preview and Nerve Response Analysis Apps
still require independent ownership review.
