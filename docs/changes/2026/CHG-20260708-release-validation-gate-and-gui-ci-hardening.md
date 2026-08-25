# Release validation gate and GUI CI hardening

```labkit-change
id: CHG-20260708-release-validation-gate-and-gui-ci-hardening
date: 2026-07-08
type: ci
compatibility: compatible
component: repository
```

## Why

Release-candidate tags did not yet require one explicit summary gate over the headless, coverage, and GUI jobs. Some GUI assertions also depended on exact pixel ordering or timing that varied across CI display backends.

### Accepted choice

Require every release test job before publication, while testing semantic grid structure instead of platform-specific pixel rounding. Increase the shared GUI idle allowance so slower hosted displays can finish registered UI work.

## What changed

- Project validation workflow, no component version change.

- Release candidate tags now run the full MATLAB test workflow gate before publication: headless tests, coverage, GUI tests, and a release summary gate.
- GUI layout tests now assert structural grid contracts instead of platform-dependent flattened pixel ordering or width comparisons.
- Shared GUI test idle waiting allows slower CI display backends more time to finish registered UI work.

## Impact

Published release candidates gained a single pass/fail validation signal. Application behavior and data formats did not change; the GUI suite became less sensitive to harmless platform layout differences.

## Compatibility and limits

- No known manual migration.

### Remaining limits

The gate covers automated checks only. Interactive workflow feel and scientific visual review remain outside hosted CI.
