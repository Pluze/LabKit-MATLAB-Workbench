# Nerve Response Analysis uses fixed source identities

```labkit-change
id: LK-20260716-nerve-response-structure
date: 2026-07-16
sequence: 107
type: refactor
compatibility: compatible
component: `labkit_NerveResponseAnalysis_app` | `1.4.2 -> 1.4.3`
scope: Neurophysiology
scope: App structure
```

## Context

Nerve Response Analysis split one project schema across generic lifecycle
files and kept two additional lifecycle helpers to filter and replace source
records by role. Product metadata remained in separate requirement/version
functions, while session and presentation code read nested portable-reference
fields directly.

## Decision and rationale

Use `filterRecord` and `protocol` as the two stable App-owned source IDs and
matching roles. Runtime V2 already supports semantic path lookup by ID and an
injected upsert service, so role-filter wrappers duplicate framework behavior
without adding scientific meaning. Keep event detection, recording analysis,
CAP measurement, presentation, and result writing in their existing concrete
workflow packages.

## Changes

- Consolidated command identity, display metadata, version, requirements,
  project, session, layout, actions, presenter, renderer, and debug capability
  through the single definition.
- Concentrated project creation, validation, and the version-1 source upgrade
  in `projectSpec` behind one `Migrate` callback.
- Moved parsed JSON and transient workflow reconstruction to root
  `createSession`.
- Replaced App-owned role filtering/replacement helpers with `sourcePaths` and
  the injected `upsertSource` service.
- Strengthened validation so the two source IDs are unique, supported, and
  match their declared roles.
- Removed the generic lifecycle package and separate requirement/version files.

## User and data impact

Filter/protocol selection, run limits, event and train detection, CAP metrics,
issue handling, previews, output-folder defaults, JSON export, manifest output,
reset, and project reopening are unchanged. The App version advances to 1.4.3;
durable payload version remains 2.

## Compatibility and migration

Version-1 projects still combine their separate filter and protocol records
into the canonical source collection. Runtime V2 invokes the single migration
entry and owns iteration. Current version-2 files already written with the
documented fixed IDs load without data transformation.

## Validation

Focused unit tests cover migration, source identity validation, event trains,
differential/common-mode calculations, CAP metrics, filter labels, and the
legacy keep-column input. The hidden GUI workflow covers filter selection,
analysis, counts/issues presentation, JSON and manifest export, project save,
reset, reopen, and reanalysis.

## Evidence

- [Nerve Response Analysis](../../../../apps/neurophysiology/nerve-response-analysis/README.md)
- [RHS Preview](../../../../apps/neurophysiology/rhs-preview/README.md)
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)

## Known limitations and follow-up

Automated tests do not establish that a selected protocol, stimulation source,
or timing window is physiologically correct. RHS Preview still uses the older
split lifecycle structure and requires its own independent convergence review.
