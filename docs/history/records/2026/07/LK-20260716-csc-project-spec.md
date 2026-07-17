# CSC consolidates its product and project contracts

```labkit-change
schema: 2
id: LK-20260716-csc-project-spec
date: 2026-07-16
sequence: 88
type: refactor
compatibility: compatible
component: `labkit_CSC_app` | `1.4.1 -> 1.4.2`
scope: Electrochemistry
scope: Project lifecycle
```

## Context

CSC split product metadata across three files and its durable schema across a
generic lifecycle package even though it has no historical payload migration.
The additional entry points did not own distinct electrochemical behavior.

## Decision and rationale

Make `definition.m` the complete product declaration and `projectSpec.m` the
sole durable-schema entry. Keep `createSession.m` explicit because reloading
CV/CT curves and restoring file/cycle selection is genuine transient work.

## Changes

- Consolidated command metadata, version, update date, and requirements in the
  definition.
- Consolidated project defaults and validation behind one project spec.
- Moved decoded curve and selection restoration to a package-root session
  factory.
- Removed separate metadata files and the generic lifecycle package.
- Kept integration formulas, sign splitting, scan-rate handling, area
  normalization, plots, and export schemas unchanged.

## User and developer impact

Launch, source and cycle selection, save/load, calculations, plots, and both
export paths behave unchanged. The durable contract is now readable in one
place without hiding scientific behavior in the framework.

## Compatibility and migration

The project remains version 1 with identical fields, defaults, validation, and
source records. Existing CSC projects require no migration.

## Validation

Unit tests cover CT/CV calculations, edge-cycle policy, normalization, result
tables, export schemas, project/session contracts, and presentation. The
hidden GUI workflow covers real launch, file/cycle selection, calculation,
save/load, plot overlays, and exports.

## Evidence

- [CSC](../../../../apps/electrochemistry/csc/README.md)
- [Runtime and Lifecycle](../../../../framework/runtime.md)

## Known limitations and follow-up

Decoded source restoration still reaches into portable-reference internals.
That cross-App framework boundary remains scheduled for one shared source-path
service rather than an App-specific wrapper.
