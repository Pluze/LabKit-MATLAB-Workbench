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

- This is the period where LabKit changed from loose scripts into an app
  workbench with a small reusable foundation.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

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

- This is the period where LabKit changed from loose scripts into an app
  workbench with a small reusable foundation.

## Compatibility and migration

- Component/app version files did not exist yet, so this era is tracked by
  release tags, commit ranges, and workflow milestones rather than per-app
  version numbers.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main history from `5973bde0` through `a7e7dfb1`.
- Release tags: `v1.0`, `v2.0`, `2.1`, `v2.2.0`, `v2.3.0`, `v2.3.1`,
  `v2.3.2`, `v2.3.3`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
