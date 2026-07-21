# Figure Studio removes source-reference knowledge

```labkit-change
id: LK-20260716-figure-studio-source-boundary
date: 2026-07-16
sequence: 94
type: refactor
compatibility: compatible
component: `labkit_FigureStudio_app` | `0.2.3 -> 0.2.4`
scope: LabKit Core Apps
scope: Runtime source boundary
```

## Context

Figure Studio read both the current path and stored filename from the nested
portable source reference. It repeated those reads in session reconstruction,
actions, file-list presentation, and selection lookup.

## Decision and rationale

Resolve source paths once through Runtime V2 at each workflow boundary. Derive
the displayed filename from the resolved path so the App needs no knowledge of
any portable-reference field.

## Changes

- Migrated FIG session reconstruction, action loading, file presentation, and
  selection lookup to `labkit.ui.runtime.sourcePaths`.
- Derived the opened-file status name through `fileparts`.
- Removed every direct portable-reference field read from Figure Studio.
- Preserved imported axes data, default style adoption, source order, current
  selection, editing, and export behavior.

## User and data impact

FIG selection and display behave unchanged. Figure Studio now owns only how it
uses a resolved FIG file; Runtime V2 owns how that file remains portable.

## Compatibility and migration

No project or source-record field changed. Existing Figure Studio projects
require no migration.

## Validation

Source-axes and result-file unit tests cover import and export semantics. The
hidden GUI suite covers empty startup, FIG addition and selection, style
presentation, save/load, and output workflows.

## Evidence

- [Figure Studio](../../../../apps/labkit-core/figure-studio/README.md)
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)

## Known limitations and follow-up

The repository-wide portable-reference guard remains deferred until all
remaining App families have migrated.
