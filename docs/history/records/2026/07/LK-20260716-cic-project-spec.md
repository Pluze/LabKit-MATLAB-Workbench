# CIC consolidates its project contract without losing lazy loading

```labkit-change
schema: 2
id: LK-20260716-cic-project-spec
date: 2026-07-16
sequence: 87
type: refactor
compatibility: compatible
component: `labkit_CIC_app` | `1.4.1 -> 1.4.2`
scope: Electrochemistry
scope: Project lifecycle
```

## Context

CIC split static metadata across three files and its first-version project
across a generic lifecycle package. Its session factory also encodes an
important performance policy: restore only the first source for preview rather
than parsing an entire large batch.

## Decision and rationale

Consolidate product metadata in `definition.m` and durable schema behavior in
`projectSpec.m`. Keep `createSession.m` separate and explicit because lazy
source decoding is real transient reconstruction and a user-visible
performance boundary, not lifecycle boilerplate.

## Changes

- Moved command metadata, version, update date, and requirements into the
  definition.
- Consolidated project defaults and validation behind one project spec.
- Moved lazy preview restoration to one package-root session factory.
- Removed separate metadata files and the generic lifecycle package.
- Kept pulse detection, CIC formulas, units, limits, plots, and exports
  unchanged.

## User and developer impact

Launch, source selection, large-batch behavior, computation, save/load, and CSV
exports behave unchanged. The App structure is smaller while the reason for
its lazy session factory is now documented next to the code.

## Compatibility and migration

The project remains version 1 with identical fields, defaults, validation, and
source records. Existing CIC projects require no migration.

## Validation

Unit tests cover the project contract, CIC calculation, units, failed rows,
CSV schema, and presentation. The hidden GUI workflow covers real launch,
source selection, calculation, save/load, and export through Runtime V2.

## Evidence

- [CIC](../../../../apps/electrochemistry/cic/README.md)
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)

## Known limitations and follow-up

The session currently reads `reference.originalPath` directly. That internal
portable-reference representation will be replaced by a simple framework
source-path service across all Apps rather than patched only in CIC.
