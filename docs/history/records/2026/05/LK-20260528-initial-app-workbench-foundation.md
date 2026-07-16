# Initial app workbench foundation

```labkit-change
schema: 1
id: LK-20260528-initial-app-workbench-foundation
date: 2026-05-28
type: feat
compatibility: compatible
scope: historical project evolution
```

## Context

LabKit began as a collection of MATLAB scripts and GUI entry points. The first
release series established independent apps, a launcher, and reusable code for
file parsing and common UI behavior.

## Decision and rationale

Organize the imported workflows as separately launchable apps instead of one
monolithic analysis program. Share only mechanics that were useful across
apps, while keeping experiment-specific calculations and outputs with their
owning workflow.

## Changes

- Release tags `v1.0`, `v2.0`, legacy `2.1`, `v2.2.0`, `v2.3.0`, `v2.3.1`,
  `v2.3.2`, and `v2.3.3`.

- Imported legacy MATLAB code and split it into app entry points.
- Extracted DTA parsers, electrochem calculations, DIC workflows, image
  measurement workflows, biosignal support, and ECG workflows.
- Replaced root legacy GUI entry points with package-backed runners.
- Added app shell behavior, axes popout, shared UI controls, debug trace
  logging, launcher/project metadata, release updater support, and reproducible
  release-asset rules.

## User and data impact

Users gained named app commands and a launcher instead of opening unrelated
legacy scripts manually. Existing laboratory files remained external inputs;
the workbench did not convert them into a central LabKit data store.

## Compatibility and migration

- Component/app version files did not exist yet, so this era is tracked by
  release tags, commit ranges, and workflow milestones rather than per-app
  version numbers.

## Validation

Historical test commands were not recorded consistently. The commit range and
release tags below identify the code that was shipped during this period.

## Evidence

- Main history from `5973bde0` through `a7e7dfb1`.
- Release tags: `v1.0`, `v2.0`, `2.1`, `v2.2.0`, `v2.3.0`, `v2.3.1`,
  `v2.3.2`, `v2.3.3`.

## Known limitations and follow-up

Per-component version files and structured validation records were introduced
later, so exact app-by-app changes in this period must be traced through the
listed tags and commits.
