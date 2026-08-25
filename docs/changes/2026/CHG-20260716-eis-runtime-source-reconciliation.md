# EIS delegates source identity reconciliation to Runtime V2

```labkit-change
id: CHG-20260716-eis-runtime-source-reconciliation
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_EIS_app | 1.4.3 -> 1.4.4
```

## Why

EIS already stored only portable source records in its durable project, but its action file still generated source IDs, appended records, and removed records with App-local helpers. That duplicated Runtime V2's source reconciliation service and made the App responsible for an identity invariant owned by project persistence.

The EIS session factory also repeated empty workflow and view buckets even though Runtime V2 canonicalizes missing transient buckets.

### Accepted choice

Use `services.project.reconcileSources` as the single source-record owner after successful file additions, removals, and clearing. The EIS workflow continues to decide which decoded files are accepted and their order; Runtime preserves matching source identities and allocates collision-free identities for new files.

Return only EIS-specific selection and decoded-cache state from `createSession`. Runtime supplies the empty workflow and view buckets before the state becomes visible to actions or presenters.

## What changed

- Removed EIS-local source-ID generation, append, and removal helpers.
- Reconciled durable source records from the successfully decoded EIS items.
- Removed empty workflow and view boilerplate from the session factory.
- Added GUI assertions for canonical Runtime buckets, unique source IDs, and identity preservation across additions and project reopen.
- Advanced the EIS App version to 1.4.4.

## Impact

File selection, decoding, plotting, export, save, and reopen behavior are unchanged. Existing saved source IDs remain stable when their paths match. Newly added records receive Runtime-managed IDs. IDs are persistence identities and are not displayed as scientific results.

## Compatibility and limits

The project payload remains version 1 and needs no migration. Existing project files continue to load through their stored portable references.

### Remaining limits

Other multi-file Apps still contain equivalent local source-list helpers. They should adopt the same Runtime service only after their role and ordering semantics are verified by their own focused tests.
