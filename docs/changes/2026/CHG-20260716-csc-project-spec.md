# CSC consolidates its product and project contracts

```labkit-change
id: CHG-20260716-csc-project-spec
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_CSC_app | 1.4.1 -> 1.4.2
```

## Why

CSC split product metadata across three files and its durable schema across a generic lifecycle package even though it has no historical payload migration. The additional entry points did not own distinct electrochemical behavior.

### Accepted choice

Make `definition.m` the complete product declaration and `projectSpec.m` the sole durable-schema entry. Keep `createSession.m` explicit because reloading CV/CT curves and restoring file/cycle selection is genuine transient work.

## What changed

- Consolidated command metadata, version, update date, and requirements in the definition.
- Consolidated project defaults and validation behind one project spec.
- Moved decoded curve and selection restoration to a package-root session factory.
- Removed separate metadata files and the generic lifecycle package.
- Kept integration formulas, sign splitting, scan-rate handling, area normalization, plots, and export schemas unchanged.

## Impact

Launch, source and cycle selection, save/load, calculations, plots, and both export paths behave unchanged. The durable contract is now readable in one place without hiding scientific behavior in the framework.

## Compatibility and limits

The project remains version 1 with identical fields, defaults, validation, and source records. Existing CSC projects require no migration.

### Remaining limits

Decoded source restoration still reaches into portable-reference internals. That cross-App framework boundary remains scheduled for one shared source-path service rather than an App-specific wrapper.
