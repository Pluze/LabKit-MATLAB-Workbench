# Release validation gate and GUI CI hardening

```labkit-change
schema: 1
id: LK-20260708-release-validation-gate-and-gui-ci-hardening
date: 2026-07-08
type: ci
compatibility: compatible
scope: historical project evolution
```

## Context

Release-candidate tags did not yet require one explicit summary gate over the
headless, coverage, and GUI jobs. Some GUI assertions also depended on exact
pixel ordering or timing that varied across CI display backends.

## Decision and rationale

Require every release test job before publication, while testing semantic grid
structure instead of platform-specific pixel rounding. Increase the shared GUI
idle allowance so slower hosted displays can finish registered UI work.

## Changes

- Project validation workflow, no component version change.

- Release candidate tags now run the full MATLAB test workflow gate before
  publication: headless tests, coverage, GUI tests, and a release summary gate.
- GUI layout tests now assert structural grid contracts instead of
  platform-dependent flattened pixel ordering or width comparisons.
- Shared GUI test idle waiting allows slower CI display backends more time to
  finish registered UI work.

## User and data impact

Published release candidates gained a single pass/fail validation signal.
Application behavior and data formats did not change; the GUI suite became less
sensitive to harmless platform layout differences.

## Compatibility and migration

- No known manual migration.

## Validation

Commit `f359518` updated CI policy tests, declarative UI tests, launcher GUI
tests, and shared wait behavior.

## Evidence

- Mainline commit `f359518`.

## Known limitations and follow-up

The gate covers automated checks only. Interactive workflow feel and scientific
visual review remain outside hosted CI.
