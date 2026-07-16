# Launcher code-analysis export

```labkit-change
schema: 1
id: LK-20260701-launcher-code-analysis-export
date: 2026-07-01
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.1.6 -> 1.2.0`
```

## Context

- Maintainers can inspect launcher code issues through the workbench tooling
  without a separate manual MATLAB setup.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit_launcher` `1.1.6 -> 1.2.0`

- Exported launcher Code Analyzer issues natively.

## User and data impact

- Maintainers can inspect launcher code issues through the workbench tooling
  without a separate manual MATLAB setup.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `8fd3ddff`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
