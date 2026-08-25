# VT Resistance consolidates its project contract

```labkit-change
id: CHG-20260716-vt-resistance-project-spec
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_VTResistance_app | 1.4.1 -> 1.4.2
```

## Why

VT Resistance split static product metadata across three files and its first-version project across a generic lifecycle package. Its session factory also encodes a real performance policy by loading only the first preview source.

### Accepted choice

Make `definition.m` the complete product declaration and `projectSpec.m` the sole durable-schema entry. Keep `createSession.m` explicit because lazy DTA decoding and analysis is transient reconstruction, not lifecycle boilerplate.

## What changed

- Consolidated command metadata, version, update date, and requirements in the definition.
- Consolidated project defaults and validation behind one project spec.
- Moved lazy preview restoration to a package-root session factory.
- Removed separate metadata files and the generic lifecycle package.
- Added a direct project/session contract assertion to the VT export suite.
- Kept pulse detection, steady windows, voltage definitions, resistance formulas, plots, and export schemas unchanged.

## Impact

Launch, batch loading, selection, calculation, save/load, plotting, and CSV exports behave unchanged. The durable contract and lazy reconstruction policy are now explicit and adjacent.

## Compatibility and limits

The project remains version 1 with identical fields, defaults, validation, and source records. Existing VT Resistance projects require no migration.

### Remaining limits

The lazy session still reaches into portable-reference internals. The shared source-path boundary will replace this across all Apps in one framework change.
