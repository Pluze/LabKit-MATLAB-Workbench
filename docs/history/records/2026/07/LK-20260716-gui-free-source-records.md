# Runtime exposes GUI-free source-record creation

```labkit-change
schema: 2
id: LK-20260716-gui-free-source-records
date: 2026-07-16
sequence: 100
type: feat
compatibility: additive
component: `labkit.ui` | `7.4.1 -> 7.4.2`
scope: Runtime V2 sources
scope: App project migration
```

## Context

Runtime V2 owned the portable-reference schema and exposed a stable path
accessor, but source-record creation was available only through callback-bound
project services. GUI-free project migrations and legacy importers therefore
could not create canonical sources without copying private reference fields.
Batch Crop and Video Marker both contained such schema copies.

## Decision and rationale

Expose the canonical source record, not the portable-reference implementation.
`labkit.ui.runtime.sourceRecord` accepts stable App identity, semantic role,
path, and required status, then delegates the nested representation to the
Runtime. The injected callback service uses the same factory.

## Changes

- Added the GUI-free `labkit.ui.runtime.sourceRecord` factory with validation
  and complete MATLAB help.
- Routed `services.project.sourceRecord`, `upsertSource`, and
  `reconcileSources` through the same public contract.
- Extended source tests to cover factory output and invalid inputs.
- Updated the framework API map and portable-source guidance.

## User and developer impact

User project behavior is unchanged. App authors can now implement project
migrations and legacy imports without opening a UI callback or constructing
runtime-owned reference fields. Current file paths remain available only
through `sourcePaths`.

## Compatibility and migration

The addition is compatible within UI 7. Existing source records and injected
services retain their shape and behavior. Apps should replace copied portable
reference construction when their project/import code is migrated.

## Validation

Focused Runtime source tests cover empty arrays, canonical creation, resolved
path lookup, ordered/optional ID lookup, invalid references, and invalid
factory arguments. Package-surface, version, documentation, and history
guardrails protect the new public contract.

## Evidence

- [Runtime and Lifecycle](../../../../framework/runtime.md)
- [App Framework](../../../../framework/README.md)
- [Architecture](../../../../development/architecture.md)

## Known limitations and follow-up

Existing Apps that still copy or read portable-reference fields must migrate
to `sourceRecord` and `sourcePaths` before the legacy source boundary is fully
retired.
