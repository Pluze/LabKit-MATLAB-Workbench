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

- Maintainers get a concrete pre-publication release signal that covers all
  supported automated test projects, and GUI CI should fail on contract drift
  rather than platform layout rounding.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- Project validation workflow, no component version change.

- Release candidate tags now run the full MATLAB test workflow gate before
  publication: headless tests, coverage, GUI tests, and a release summary gate.
- GUI layout tests now assert structural grid contracts instead of
  platform-dependent flattened pixel ordering or width comparisons.
- Shared GUI test idle waiting allows slower CI display backends more time to
  finish registered UI work.

## User and data impact

- Maintainers get a concrete pre-publication release signal that covers all
  supported automated test projects, and GUI CI should fail on contract drift
  rather than platform layout rounding.

## Compatibility and migration

- No known manual migration.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Mainline commit `f359518`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
