# DIC Preprocess consolidates product and project declarations

```labkit-change
id: CHG-20260716-dic-preprocess-project-spec
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_DICPreprocess_app | 1.5.1 -> 1.5.2
```

## Why

DIC Preprocess split static product metadata across three files and split one version-1 durable schema across a generic lifecycle package. That structure made a maintainer traverse six declarations before reaching any registration, crop, or mask behavior.

### Accepted choice

Make `definition.m` the complete product declaration and `projectSpec.m` the only durable-schema entry. Keep `createSession.m` explicit because decoding source images and replaying alignment/crop steps reconstructs transient cache state rather than defining persistence.

## What changed

- Moved command metadata, version, update date, and facade requirements into the definition.
- Consolidated project defaults and validation behind one project spec.
- Moved transient image and edit replay to one package-root session factory.
- Removed the metadata files and generic lifecycle package.
- Kept registration, crop, mask, history, managed interactions, export, and scientific parameter behavior unchanged.

## Impact

Manual and automatic alignment, zoom-preserving point/ROI editing, crop and mask history, project save/load, and exports behave unchanged. The durable and transient state boundaries are now visible from two adjacent files.

## Compatibility and limits

The command, project ID, payload version, fields, defaults, validation, source records, edit steps, and mask history are unchanged. Existing projects require no migration.

### Remaining limits

The `+appState` package mixes edit-history and mask-geometry capabilities. It is retained for this compatibility-preserving checkpoint and will be split or renamed by responsibility after its callers and tests are audited.
