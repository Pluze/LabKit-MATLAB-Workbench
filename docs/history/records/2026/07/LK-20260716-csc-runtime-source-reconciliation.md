# CSC delegates decoded-source identity to Runtime V2

```labkit-change
id: LK-20260716-csc-runtime-source-reconciliation
date: 2026-07-16
sequence: 113
type: refactor
compatibility: compatible
component: `labkit_CSC_app` | `1.4.3 -> 1.4.4`
scope: Electrochemistry
scope: App structure
scope: Runtime adoption
```

## Context

CSC eagerly decodes accepted CV/CT files and keeps decoded item order aligned
with durable source order. Its action file nevertheless generated source IDs,
appended records, and deleted records by index. The session factory also
declared empty workflow and view buckets already guaranteed by Runtime V2.

Those mechanics were framework persistence responsibilities rather than CSC
curve-selection or scientific behavior.

## Decision and rationale

Continue using successfully decoded item order as the App-owned source order,
then reconcile durable records through
`services.project.reconcileSources` after additions, removals, and clearing.
Runtime preserves records for retained paths and allocates collision-free IDs
for new paths. CSC continues to own decoding, active file and curve selection,
plot defaults, calculation, exports, and failure messages.

Return only the CSC-specific selection fields and decoded item cache from
`createSession`; Runtime supplies missing transient buckets.

## Changes

- Removed App-local source-ID generation and source append helpers.
- Reconciled source records from the decoded item list.
- Replaced the growing failure array with a single first-failure record while
  retaining per-file workflow logs.
- Removed empty workflow and view session boilerplate.
- Added GUI checks for canonical buckets and stable, unique identities across
  add, save, reopen, removal, and re-addition.
- Advanced the CSC App version to 1.4.4.

## User and data impact

File order, selected curve, plot resets, CSC calculations, reload, exports,
logs, and saved projects retain their behavior. Retained source identities no
longer depend on App-local append/delete logic. Scientific values and result
schemas are unchanged.

## Compatibility and migration

The current project payload remains version 1 and needs no migration. Existing
portable records retain their IDs when the corresponding paths remain loaded.

## Validation

The CSC hidden GUI workflow covers two-file decoding, file and cycle
selection, plot changes, calculation display, export, save, clear, reopen,
remove, re-add, source identity, and final plot clearing. Focused CSC
calculation/view and repository contract tests cover the remaining behavior.

## Evidence

- [Charge-Storage Capacity](../../../../apps/electrochemistry/csc/README.md)
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)
- [App Development](../../../../development/build-apps/app-development.md)

## Known limitations and follow-up

VT Resistance remains the last electrochem batch App with the same local
source-ID and append pattern and requires a separate behavior audit.
