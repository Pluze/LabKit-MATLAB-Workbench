# CIC uses Runtime-owned source and workflow mechanics

```labkit-change
id: LK-20260716-cic-runtime-source-reconciliation
date: 2026-07-16
sequence: 112
type: refactor
compatibility: compatible
component: `labkit_CIC_app` | `1.4.3 -> 1.4.4`
scope: Electrochemistry
scope: App structure
scope: Runtime adoption
```

## Context

CIC intentionally registers paths before decoding them so large batches remain
lazy, but it still generated, appended, and deleted portable source records in
App code. It also wrote directly to `session.workflow.logLines`, requiring its
session factory to reproduce Runtime-owned empty workflow and view buckets.

Those details increased the amount of framework structure an App maintainer
had to understand without expressing CIC analysis behavior.

## Decision and rationale

CIC continues to own the ordered lazy path set, current-index policy, deferred
decoding, scientific options, and result workflow. It now passes that ordered
path set to `services.project.reconcileSources` after add, removal, and clear
operations. Runtime preserves matching identities and allocates new unique
ones.

Analysis messages use `services.workflow.log`, the same service as other
workflow messages. `createSession` returns only CIC-specific selection and
decoded-cache state; Runtime creates missing transient buckets before actions
run.

## Changes

- Removed App-local source-ID generation and source append helpers.
- Reconciled registered paths through the Runtime project service.
- Routed analysis messages through the Runtime workflow service.
- Removed empty workflow and view boilerplate from `createSession`.
- Added GUI checks for stable and unique identities across batch add, save,
  reopen, removal, and re-addition.
- Advanced the CIC App version to 1.4.4.

## User and data impact

Lazy decoding, file order, selected preview, analysis values, plots, exports,
logs, and project files retain their behavior. Source identities remain stable
for retained files and collision-free for newly registered files. Scientific
calculations and output schemas are unchanged.

## Compatibility and migration

The current project payload remains version 1 and needs no migration. Existing
source records and their identities are preserved when reopened.

## Validation

The CIC hidden GUI workflow covers three-source lazy registration, selection,
whole-batch recomputation, export, save, clear, reopen, remove, re-add, source
identity, viewport refresh, and final clear. Focused calculation/view, App
structure, version, documentation, and history tests cover the surrounding
contracts.

## Evidence

- [Charge-Injection Capacity](../../../../apps/electrochemistry/cic/README.md)
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)
- [App Development](../../../../development/build-apps/app-development.md)

## Known limitations and follow-up

CSC and VT Resistance still own similar source registration helpers. Their
result indexing and lazy-load behavior must be checked independently before
adopting the Runtime service.
