# Image Match adopts capability-owned structure

```labkit-change
id: LK-20260716-image-match-structure
date: 2026-07-16
sequence: 96
type: refactor
compatibility: compatible
component: `labkit_ImageMatch_app` | `1.6.2 -> 1.6.3`
scope: Image Measurement
scope: App structure
```

## Context

Image Match split metadata and project lifecycle across eight structural files,
used an App startup callback only for an output-folder default and debug line,
and grouped unrelated source, analysis, and export structures under
`+appState`. Session, actions, and presentation also read portable-reference
path fields directly.

## Decision and rationale

Adopt one definition, one project spec, and one session factory. Place each
data constructor beside the capability that owns its meaning: loaded image
items with source reading, match steps with analysis, and idempotent export
tasks with result writing.

## Changes

- Consolidated command metadata, version, requirements, and optional
  capabilities in `definition.m`.
- Consolidated version-1 project creation and validation in `projectSpec.m`.
- Moved selected-image reconstruction to root `createSession.m`.
- Replaced `+appState` with capability-owned source, analysis, and result
  functions.
- Removed the metadata files, generic lifecycle package, and redundant startup
  callback.
- Replaced all portable-reference field reads with the Runtime path accessor.
- Corrected the GUI-free manual example to use the real `applyPipeline`
  argument order and cell output.

## User and data impact

Reference/source selection, lazy preview loading, match history, calculation,
duplicate-export detection, project reopen, and export formats behave
unchanged. A new project no longer writes an environment-specific output path
during startup; source selection still establishes the same adjacent default.

The directory now answers where an item, step, or export task belongs without
requiring knowledge of a generic state layer.

## Compatibility and migration

The durable payload remains version 1 with identical fields and validation.
Existing Image Match projects require no migration.

## Validation

Unit tests cover the definition/project/session contract, matching methods,
pipeline replay, preview scaling, result tables, export formats, manifests, and
task fingerprints. The hidden GUI suite covers reference/source loading,
selection, history, preview, export, and save/load workflows.

## Evidence

- [Image Match](../../../../apps/image-measurement/image-match/README.md)
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)

## Known limitations and follow-up

Other Image Measurement Apps retain older lifecycle or state packages and will
be reviewed against their own capabilities.
