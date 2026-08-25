# CSC delegates decoded-source identity to Runtime V2

```labkit-change
id: CHG-20260716-csc-runtime-source-reconciliation
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_CSC_app | 1.4.3 -> 1.4.4
```

## Why

CSC eagerly decodes accepted CV/CT files and keeps decoded item order aligned with durable source order. Its action file nevertheless generated source IDs, appended records, and deleted records by index. The session factory also declared empty workflow and view buckets already guaranteed by Runtime V2.

Those mechanics were framework persistence responsibilities rather than CSC curve-selection or scientific behavior.

### Accepted choice

Continue using successfully decoded item order as the App-owned source order, then reconcile durable records through `services.project.reconcileSources` after additions, removals, and clearing. Runtime preserves records for retained paths and allocates collision-free IDs for new paths. CSC continues to own decoding, active file and curve selection, plot defaults, calculation, exports, and failure messages.

Return only the CSC-specific selection fields and decoded item cache from `createSession`; Runtime supplies missing transient buckets.

## What changed

- Removed App-local source-ID generation and source append helpers.
- Reconciled source records from the decoded item list.
- Replaced the growing failure array with a single first-failure record while retaining per-file workflow logs.
- Removed empty workflow and view session boilerplate.
- Added GUI checks for canonical buckets and stable, unique identities across add, save, reopen, removal, and re-addition.
- Advanced the CSC App version to 1.4.4.

## Impact

File order, selected curve, plot resets, CSC calculations, reload, exports, logs, and saved projects retain their behavior. Retained source identities no longer depend on App-local append/delete logic. Scientific values and result schemas are unchanged.

## Compatibility and limits

The current project payload remains version 1 and needs no migration. Existing portable records retain their IDs when the corresponding paths remain loaded.

### Remaining limits

VT Resistance remains the last electrochem batch App with the same local source-ID and append pattern and requires a separate behavior audit.
