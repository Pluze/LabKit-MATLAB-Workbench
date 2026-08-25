# EIS consolidates its product and project contracts

```labkit-change
id: CHG-20260716-eis-project-spec
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_EIS_app | 1.4.1 -> 1.4.2
```

## Why

EIS split static product metadata across three files and one first-version project schema across a generic lifecycle package. Those files did not own separate impedance or plotting contracts.

### Accepted choice

Make `definition.m` the complete product declaration and `projectSpec.m` the sole durable-schema entry. Keep `createSession.m` explicit because restoring decoded ZCURVE items and source selection is genuine transient work.

## What changed

- Consolidated command metadata, version, update date, and requirements in the definition.
- Consolidated project defaults and validation behind one project spec.
- Moved decoded curve and selection restoration to a package-root session factory.
- Removed separate metadata files and the generic lifecycle package.
- Delayed log-scale assignment until filtered positive data establishes valid automatic limits, and corrected the GUI regression fixture to use a legal positive manual range while testing stale-zoom replacement.
- Kept impedance values, Nyquist/Bode axis semantics, log scaling, zoom behavior, and export schemas unchanged.

## Impact

Launch, multi-file selection, plotting, zoom, save/load, and export behavior remain unchanged. Project and transient state ownership are now adjacent and explicit.

## Compatibility and limits

The project remains version 1 with identical fields, defaults, validation, and source records. Existing EIS projects require no migration.

### Remaining limits

Source restoration still consumes portable-reference internals. The planned shared source-path service will remove that leak across all Apps together.
