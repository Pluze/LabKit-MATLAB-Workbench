# Image App project validation ownership

```labkit-change
schema: 2
id: LK-20260716-image-project-validation-ownership
date: 2026-07-16
sequence: 119
type: refactor
compatibility: compatible
component: `labkit_BatchImageCrop_app` | `1.7.4 -> 1.7.5`
component: `labkit_CurvatureMeasurement_app` | `1.4.4 -> 1.4.5`
component: `labkit_FLIRThermal_app` | `1.4.4 -> 1.4.5`
component: `labkit_FocusStack_app` | `1.5.3 -> 1.5.4`
component: `labkit_ImageEnhance_app` | `1.6.4 -> 1.6.5`
component: `labkit_ImageMatch_app` | `1.6.4 -> 1.6.5`
component: `labkit_VideoMarker_app` | `1.5.3 -> 1.5.4`
scope: image App project schemas
scope: App maintenance cost
```

## Context

The seven image workflow validators repeated Runtime's canonical project-bucket
checks and, in six cases, the standard portable source-record field list. Those
checks obscured the App-specific rules that actually matter: crop task
relationships, parameter ranges, annotation shapes, video metadata, skeleton
dimensions, and result schemas.

## Decision and rationale

Keep the existence of each App's required source collection and every
domain-specific relationship in `projectSpec.m`. Rely on Runtime for the five
canonical bucket structs and the internal shape of every supplied source
record. This preserves strict malformed-project rejection while making each
validator read as its App schema.

## Changes

- Removed 71 net lines of repeated Runtime structure checks from the seven
  image App project specifications.
- Preserved required `inputs.sources` fields and all item/source,
  annotation/source, skeleton/frame, parameter, and result constraints.
- Added a GUI-free contract that accepts all seven default projects and rejects
  each project when its App-required source collection is removed.

## User and data impact

Valid projects, migrations, image calculations, annotations, and exports are
unchanged. Malformed source records continue to fail in Runtime; malformed
App fields continue to fail in the owning App validator.

## Compatibility and migration

No payload format changed and no migration is required. The refactor changes
which layer reports framework-owned structure failures, not which valid data
the Apps accept.

## Validation

The focused project-spec contract covers default acceptance and missing-source
rejection for every affected App. Existing focused unit and hidden-GUI tests
cover the domain relationships and representative load, edit, analyze, and
export workflows.

## Evidence

- [Runtime and Lifecycle](../../../../framework/runtime.md) defines canonical
  project and source validation.
- Each affected [Image Measurement App](../../../../apps/image-measurement/README.md)
  manual lists its remaining project and session responsibilities.

## Known limitations and follow-up

This change does not shorten action handlers or scientific workflow code.
Those remain App-owned unless a separately measured repeated behavior proves
to be stable and domain-neutral.
