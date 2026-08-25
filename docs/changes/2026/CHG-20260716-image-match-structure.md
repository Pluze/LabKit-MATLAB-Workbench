# Image Match adopts capability-owned structure

```labkit-change
id: CHG-20260716-image-match-structure
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_ImageMatch_app | 1.6.2 -> 1.6.3
```

## Why

Image Match split metadata and project lifecycle across eight structural files, used an App startup callback only for an output-folder default and debug line, and grouped unrelated source, analysis, and export structures under `+appState`. Session, actions, and presentation also read portable-reference path fields directly.

### Accepted choice

Adopt one definition, one project spec, and one session factory. Place each data constructor beside the capability that owns its meaning: loaded image items with source reading, match steps with analysis, and idempotent export tasks with result writing.

## What changed

- Consolidated command metadata, version, requirements, and optional capabilities in `definition.m`.
- Consolidated version-1 project creation and validation in `projectSpec.m`.
- Moved selected-image reconstruction to root `createSession.m`.
- Replaced `+appState` with capability-owned source, analysis, and result functions.
- Removed the metadata files, generic lifecycle package, and redundant startup callback.
- Replaced all portable-reference field reads with the Runtime path accessor.
- Corrected the GUI-free manual example to use the real `applyPipeline` argument order and cell output.

## Impact

Reference/source selection, lazy preview loading, match history, calculation, duplicate-export detection, project reopen, and export formats behave unchanged. A new project no longer writes an environment-specific output path during startup; source selection still establishes the same adjacent default.

The directory now answers where an item, step, or export task belongs without requiring knowledge of a generic state layer.

## Compatibility and limits

The durable payload remains version 1 with identical fields and validation. Existing Image Match projects require no migration.

### Remaining limits

Other Image Measurement Apps retain older lifecycle or state packages and will be reviewed against their own capabilities.
