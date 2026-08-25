# Minimal App contract and current authoring manuals

```labkit-change
id: CHG-20260716-minimal-app-contract
date: 2026-07-16
type: docs
compatibility: compatible
component: labkit-project
```

## Why

Runtime V2 already supplied default project, session, action, presenter, and startup capabilities, but the complete-App tutorial and several current manuals still taught the retired split metadata and generic lifecycle package shape. The App structure guardrail also prohibited those files only when an App already owned `projectSpec.m`, leaving static Apps unprotected.

### Accepted choice

Make progressive capability the documented and tested authoring contract. A static App consists of a thin entrypoint, one definition, and one data-only layout. Actions, presentation, durable project state, transient reconstruction, and startup are added independently only when the product needs them.

## What changed

- Rewrote the complete-App tutorial around the three-file starting point and one `projectSpec.m` create/validate/migrate entry.
- Updated architecture, framework, private-App, library, testing, release, and history manuals plus scoped App rules and the App-builder skill to use definition-owned metadata and progressive optional capabilities.
- Added a hidden-GUI launch test whose definition omits every optional Runtime V2 component.
- Corrected the tutorial's numeric field declaration after the real launch test exposed its implicit text-control mismatch.
- Made the App package guardrail reject retired metadata, lifecycle, state, startup, and per-version migration files for every App shape.

## Impact

App behavior and scientific results do not change. A developer can begin with three source files and add each larger architectural concept only when a real workflow requires it. Public and private App documentation now teach the same contract.

## Compatibility and limits

This change documents and protects the already migrated Runtime V2 structure. It does not alter saved project payloads or remove the temporary low-level legacy project-migration reader used by framework tests.

### Remaining limits

The minimal contract proves framework defaults, not that every complex App has already reached its lowest maintainable complexity. App-by-App workflow and framework-boundary audits continue separately.
