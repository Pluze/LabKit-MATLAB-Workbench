# Chrono Overlay removes App-owned source identity bookkeeping

```labkit-change
id: LK-20260716-chrono-runtime-source-reconciliation
date: 2026-07-16
sequence: 111
type: fix
compatibility: compatible
component: `labkit_ChronoOverlay_app` | `1.4.3 -> 1.4.4`
scope: Electrochemistry
scope: App structure
scope: Project identity
```

## Context

Chrono Overlay generated a new source ID from the current record count. After
removing an earlier source, adding another file could therefore reuse an ID
still owned by a retained record. Runtime validation correctly rejects
duplicate IDs, but the App should not have been maintaining this persistence
invariant itself.

The App also duplicated source append/removal helpers and empty transient
workflow/view buckets already supplied by Runtime V2.

## Decision and rationale

After every successful add, removal, or clear operation, derive the ordered
path list from the decoded items and delegate durable-record reconciliation to
`services.project.reconcileSources`. Chrono Overlay continues to own decoding,
pulse-gap alignment, item order, selection, logs, and failure wording. Runtime
owns stable identity reuse and collision-free allocation.

Only App-specific selection and decoded cache data are returned by
`createSession`; Runtime canonicalizes the remaining transient buckets.

## Changes

- Removed App-local source record append, removal, and count-based ID logic.
- Reconciled source records from the accepted decoded item order.
- Removed empty workflow and view boilerplate from the session factory.
- Replaced the dynamically growing failure list with one first-failure record
  while retaining per-file log messages.
- Added a GUI regression sequence that removes the first of two sources, adds
  it again, checks unique IDs, saves, clears, and reopens the project.
- Advanced the Chrono Overlay App version to 1.4.4.

## User and data impact

Normal file loading, ordering, selection, plots, exports, and saved project
payloads retain their behavior. The remove-then-add sequence no longer risks a
duplicate source ID and failed callback. Persistence IDs remain internal and
do not change curve values or scientific output.

## Compatibility and migration

The current payload remains version 2 and no new migration is needed. Existing
records retain their IDs when their paths remain in the project.

## Validation

The Chrono Overlay hidden GUI workflow covers two-file loading, selection,
remove and re-add, unique identity, export, save, clear, reopen, option redraw,
and final plot clearing. Focused unit, structure, version, documentation, and
history tests protect the calculation and product contracts.

## Evidence

- [Chrono Overlay](../../../../apps/electrochemistry/chrono-overlay/README.md)
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)
- [App Development](../../../../development/build-apps/app-development.md)

## Known limitations and follow-up

CIC, CSC, and VT Resistance still have equivalent App-local source identity
helpers and require their own ordering and behavior audits before conversion.
