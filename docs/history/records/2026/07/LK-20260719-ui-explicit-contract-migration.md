# App SDK explicit contract begins real App migration

```labkit-change
schema: 2
id: LK-20260719-ui-explicit-contract-migration
date: 2026-07-19
sequence: 138
type: refactor
compatibility: breaking
component: `labkit.app` | `new -> 1.0.0`
component: `labkit_ChronoOverlay_app` | `1.4.7 -> 1.5.0`
scope: App Framework
scope: Electrochem
scope: Project persistence
scope: Result provenance
```

## Context

Runtime V2 removed substantial per-App lifecycle code, but Apps still
registered callback tables, repeated bound values in presenters, authored
standard file add/remove/clear behavior, and depended on nested event/service
structs. A replacement SDK kernel had already established immutable semantic
values, pre-GUI validation, transactional state/presentation commits, project
documents, result manifests, resources, and portable sources. It still needed
evidence from a real source-backed plotting App and a native MATLAB adapter.

## Decision and rationale

Create `labkit.app` as the future stable SDK rather than misnaming the expanded
contract `labkit.ui` or adapting it back to Runtime V2 transport structs. Keep
the public root small, partition authoring by capability, and concentrate
complexity in a paved path: `layout.*` nodes, collected StateHandlers, strict
bindings, runtime-completed `view.Snapshot` values, standard file lifecycle,
fixed `CreateSession(project,context)`, and private native adapters.

Chrono Overlay is the first migrated App because it exercises a project,
portable files, transient decoding, selection, bound controls, two axes,
native viewport preservation, CSV output, and a result manifest without
requiring the later managed-interaction vocabulary.

## Changes

- Added the private native MATLAB adapter with semantic component ownership,
  typed RuntimeKernel callbacks, native dialog results, complete-presentation
  reconciliation, and rollback to the previous native view after a failed
  renderer commit.
- Added `Definition.launch`, fixed renderer `(axes,model)` dispatch, semantic
  labels, runtime-owned file add/remove/clear and selection, and transient
  session rebuild after source collection changes.
- Added strict table view options, typed complete-data edits, and distinct
  `event.TableCellEdit`, `event.TableCellSelection`, and
  `event.ListSelection` values; the private adapter absorbs native MATLAB
  table-value differences.
- Fixed session construction to `CreateSession(project,context)` so Apps resolve
  opaque portable sources without reading their representation.
- Migrated Chrono Overlay to one export StateHandler, four direct bindings,
  one two-axis renderer call, and a two-operation view snapshot.
- Partitioned the public SDK into `layout`, `view`, `event`, `project`,
  `result`, and `dialog`; layout nodes, option parsing, stores, adapters, and
  runtime execution remain hidden under `internal`.
- Reduced Chrono's noncomment layout/action/presenter code from 277 lines to
  86 while preserving its DTA alignment, plot options, project schema, CSV
  columns, and result provenance.

## User and data impact

Chrono Overlay retains its input formats, pulse-gap alignment, plot meanings,
parameter defaults, CSV table, and version-2 project payload. File identities
and portable paths remain runtime-owned. Existing version-1 payload migration
still removes decoded transient items before validation.

## Compatibility and migration

`labkit.app` 1 is a source-breaking replacement contract. Apps migrate on the
branch before the UI 7 `runtime/layout` boundary is deleted; the two public
authoring surfaces are not a permanent compatibility layer. Project documents
retain their format and App payload versions independently of either facade.

## Validation

Focused headless tests cover strict values, transactional runtime behavior,
project save/restore, authoring defaults, and Chrono calculations/exports.
Hidden GUI tests cover native semantic construction, typed control and table
callbacks, bound
side effects, standard file lifecycle, transient session rebuild, two-axis
rendering, viewport preservation, renderer rollback, Chrono export, and
project restore.

## Evidence

- [Chrono Overlay](../../../../apps/electrochemistry/chrono-overlay/README.md)
- [LabKit App Framework](../../../../framework/README.md)
- [Build a Complete App](../../../../development/build-apps/complete-app.md)

## Known limitations and follow-up

Project menu/recovery UX, managed interactions, table/workspace migration
evidence, the remaining Apps, and deletion of UI 7 remain in later migration
phases. Hidden GUI tests do not replace developer-led validation of native
dialogs, pointer feel, or scientific workflow suitability.
