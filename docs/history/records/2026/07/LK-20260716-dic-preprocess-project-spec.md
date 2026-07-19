# DIC Preprocess consolidates product and project declarations

```labkit-change
schema: 2
id: LK-20260716-dic-preprocess-project-spec
date: 2026-07-16
sequence: 84
type: refactor
compatibility: compatible
component: `labkit_DICPreprocess_app` | `1.5.1 -> 1.5.2`
scope: DIC
scope: Project lifecycle
```

## Context

DIC Preprocess split static product metadata across three files and split one
version-1 durable schema across a generic lifecycle package. That structure
made a maintainer traverse six declarations before reaching any registration,
crop, or mask behavior.

## Decision and rationale

Make `definition.m` the complete product declaration and `projectSpec.m` the
only durable-schema entry. Keep `createSession.m` explicit because decoding
source images and replaying alignment/crop steps reconstructs transient cache
state rather than defining persistence.

## Changes

- Moved command metadata, version, update date, and facade requirements into
  the definition.
- Consolidated project defaults and validation behind one project spec.
- Moved transient image and edit replay to one package-root session factory.
- Removed the metadata files and generic lifecycle package.
- Kept registration, crop, mask, history, managed interactions, export, and
  scientific parameter behavior unchanged.

## User and developer impact

Manual and automatic alignment, zoom-preserving point/ROI editing, crop and
mask history, project save/load, and exports behave unchanged. The durable and
transient state boundaries are now visible from two adjacent files.

## Compatibility and migration

The command, project ID, payload version, fields, defaults, validation, source
records, edit steps, and mask history are unchanged. Existing projects require
no migration.

## Validation

Unit tests cover project/session reconstruction, state history, registration,
crop/mask calculations, source IO, exports, and presenter models. The hidden
GUI workflow covers real launch, manual point matching, ROI crop, mask editing,
viewport preservation, and generated outputs.

## Evidence

- [DIC Preprocess](../../../../apps/dic/dic-preprocess/README.md)
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)

## Known limitations and follow-up

The `+appState` package mixes edit-history and mask-geometry capabilities. It
is retained for this compatibility-preserving checkpoint and will be split or
renamed by responsibility after its callers and tests are audited.
