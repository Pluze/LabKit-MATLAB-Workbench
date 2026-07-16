# Runtime-only P-code app packages

```labkit-change
schema: 1
id: LK-20260708-runtime-only-p-code-app-packages
date: 2026-07-08
type: refactor
compatibility: compatible
scope: historical project evolution
```

## Context

- P-code distributions no longer expose or depend on launcher behavior that is
  source-checkout oriented, including launcher version/date metadata and
  follow-on packaging actions.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- Project deployment tooling, no component version change.

- `Package P-code` now creates a runtime-only single-app package instead of
  shipping a P-coded LabKit launcher and launcher maintenance tools.
- P-code package manifests and README instructions point users to the direct
  `run_<app_command>` entry file.
- P-code packaging no longer requires `labkit_launcher.m` or `labkit_launcher.p`
  to exist in the package root being used as the runtime source.

## User and data impact

- P-code distributions no longer expose or depend on launcher behavior that is
  source-checkout oriented, including launcher version/date metadata and
  follow-on packaging actions.

## Compatibility and migration

- Users of P-code packages should run `run_<app_command>` from the unzipped
  package instead of `labkit_launcher`. Source packages still include and
  support the launcher.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Mainline commit `75f63f1`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
