# DIC Postprocess adopts one product and project declaration

```labkit-change
schema: 2
id: LK-20260716-dic-postprocess-project-spec
date: 2026-07-16
sequence: 83
type: refactor
compatibility: compatible
component: `labkit_DICPostprocess_app` | `1.4.1 -> 1.4.2`
scope: DIC
scope: Project lifecycle
```

## Context

DIC Postprocess split static product metadata across `definition.m`,
`requirements.m`, and `version.m`, while its version-1 durable schema occupied
three generic `+appLifecycle` files. None of those separations represented a
separate scientific capability or independently evolving contract.

## Decision and rationale

Make `definition.m` the product declaration and `projectSpec.m` the only
durable-schema entry. Keep `createSession.m` separate because it restores
file-backed strain, image, mask, and prepared overlay caches that must not be
serialized into the project.

## Changes

- Moved command metadata, version, update date, and facade requirements into
  the definition.
- Consolidated project defaults and validation behind one project spec.
- Moved transient reconstruction to one explicitly named package-root entry.
- Removed the two metadata files and generic lifecycle package.
- Replaced the stale GUI-free manual example with an executable call matching
  the real input structure, complete parameter contract, and three outputs.
- Kept all calculation, parameter, action, presentation, and export behavior
  unchanged.

## User and developer impact

Ncorr loading, overlay preparation, statistics, save/load, and exports behave
unchanged. Maintainers can now find the complete product contract in one file
and the complete durable schema in one adjacent file.

## Compatibility and migration

The command, project ID, payload version, fields, defaults, validation rules,
and source records are unchanged. Existing DIC Postprocess projects require no
migration.

## Validation

Unit tests exercise Ncorr loading, cached session reconstruction, numerical
preparation, summary/export behavior, and presentation. The hidden GUI flow
launches the real App and generates overlays and a summary through Runtime V2.

## Evidence

- [DIC Postprocess](../../../../apps/dic/dic-postprocess/README.md)
- [Runtime and Lifecycle](../../../../framework/runtime.md)

## Known limitations and follow-up

The action file remains a meaningful workflow boundary because it coordinates
input selection, calculation, export, diagnostics, and dialogs. Its naming and
possible smaller capability boundaries will be compared across the DIC family
instead of changed in isolation.
