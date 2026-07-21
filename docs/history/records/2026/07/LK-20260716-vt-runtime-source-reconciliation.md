# VT Resistance removes source and workflow storage boilerplate

```labkit-change
id: LK-20260716-vt-runtime-source-reconciliation
date: 2026-07-16
sequence: 114
type: refactor
compatibility: compatible
component: `labkit_VTResistance_app` | `1.4.3 -> 1.4.4`
scope: Electrochemistry
scope: App structure
scope: Runtime adoption
```

## Context

VT Resistance deliberately keeps batch source registration lazy, decoding only
the selected preview until export. The App nevertheless generated and appended
portable source records itself and wrote analysis messages directly into
`session.workflow.logLines`. Its session factory consequently repeated empty
workflow and view buckets owned by Runtime V2.

## Decision and rationale

Keep lazy ordered path registration, selection, resistance analysis, plots,
and exports in VT Resistance. Delegate the conversion from that ordered path
set to stable portable records to `services.project.reconcileSources`.
Runtime preserves retained identities and allocates new unique identities.

Route analysis messages through `services.workflow.log` and return only
App-specific selection and cache state from `createSession`.

## Changes

- Removed local source-ID generation, record append, and registration lookup.
- Reconciled ordered source paths after add, removal, and clear operations.
- Routed resistance-analysis messages through the Runtime workflow service.
- Removed empty workflow and view session boilerplate.
- Added GUI checks for Runtime-supplied buckets and stable, unique source IDs
  across batch add, save, reopen, removal, and re-addition.
- Advanced the VT Resistance App version to 1.4.4.

## User and data impact

Lazy loading, current selection, resistance values, plots, logs, export
columns, and project files retain their behavior. Retained file identities are
stable and newly added files cannot collide with them. Scientific calculations
and exported numeric values are unchanged.

## Compatibility and migration

The current project payload remains version 1 and needs no migration. Existing
portable source records retain their IDs when reopened.

## Validation

The VT Resistance hidden GUI workflow covers three-source lazy registration,
selection, whole-batch recomputation, export, save, clear, reopen, remove,
re-add, and source identity. Focused resistance/export and repository contract
tests cover the surrounding calculation and product behavior.

## Evidence

- [VT Resistance](../../../../apps/electrochemistry/vt-resistance/README.md)
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)
- [App Development](../../../../development/build-apps/app-development.md)

## Known limitations and follow-up

The broader App inventory must still be scanned for local source-record
construction that represents migrations or semantic fixed slots rather than
replaceable Runtime bookkeeping.
