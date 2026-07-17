# RHS Preview separates source roles from reference mechanics

```labkit-change
schema: 2
id: LK-20260716-rhs-preview-structure
date: 2026-07-16
sequence: 108
type: refactor
compatibility: compatible
component: `labkit_RHSPreview_app` | `1.4.2 -> 1.4.3`
scope: Neurophysiology
scope: App structure
```

## Context

RHS Preview split one durable project across generic lifecycle files and used
two additional lifecycle helpers to select or replace records by role. It also
constructed variable filter-source IDs itself and read Runtime-owned reference
fields in session, actions, and presentation code. Product metadata remained
in separate requirement/version functions.

## Decision and rationale

Keep the three App-owned roles because they express real workflow meaning: one
preview recording, one optional protocol, and an ordered collection of filter
recordings. Use Runtime V2 for portable path access, fixed-source upserts, and
stable reconciliation of the variable collection. Keep only the small
App-owned role-to-path selection policy under `sourceFiles`; do not introduce a
new framework public role API for one App-specific collection shape.

## Changes

- Consolidated command identity, display metadata, version, requirements,
  project, session, layout, actions, presenter, renderer, and debug capability
  through the single definition.
- Concentrated project creation, validation, and the version-1 source upgrade
  in `projectSpec` behind one `Migrate` callback.
- Moved indexing, initial preview reads, filter discovery, and transient view
  reconstruction to root `createSession`.
- Added `sourceFiles.pathsForRole` to select App-owned source roles while
  delegating reference decoding to `labkit.ui.runtime.sourcePaths`.
- Replaced fixed-source construction with `upsertSource` and variable filter
  ID construction with `reconcileSources`, preserving filter order and stable
  identities across rediscovery.
- Removed the generic lifecycle package and separate requirement/version files.

## User and data impact

RHS indexing, lazy waveform windows, channel selection, managed ROI/scroll
interaction, protocol editing, multi-file filter labels, refresh/removal,
exports, manifests, reset, and project reopening retain their behavior. New
filter selections use Runtime-generated stable IDs; those IDs are internal
project identities and do not change exported recording paths or labels. The
App version advances to 1.4.3; durable payload version remains 2.

## Compatibility and migration

Version-1 projects still combine their separate recording, protocol, and
filter source fields before validation. Existing version-2 source IDs and
ordering are preserved when their resolved files remain selected. Runtime V2
owns migration iteration and later saves remain version 2.

## Validation

Focused unit tests cover source migration, role-path ordering, summary/detail
models, channel-role drafts, filter labels, and preview bounds. The hidden GUI
workflow covers indexing and drawing a synthetic RHS file, channel tables,
two-file filter discovery, protocol/filter export, manifests, project save,
reset, reopen, and reconstruction of both preview and filter sources.

## Evidence

- [RHS Preview](../../../../apps/neurophysiology/rhs-preview/README.md)
- [Nerve Response Analysis](../../../../apps/neurophysiology/nerve-response-analysis/README.md)
- [Runtime and Lifecycle](../../../../framework/runtime.md)

## Known limitations and follow-up

Automated tests do not assess native file-dialog feel, physical channel-role
correctness, or waveform interpretation. The remaining special startup path
and repository guidance still require separate convergence review.
