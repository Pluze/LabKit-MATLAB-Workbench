# UI diagnostics and release v3.0.0

```labkit-change
schema: 1
id: LK-20260629-ui-diagnostics-and-release-v3-0-0
date: 2026-06-29
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.1.2 -> 1.1.3`
component: `labkit.ui` | `3.1.3 -> 3.2.0`
```

## Context

- Maintainers got better evidence when app callbacks failed, and users got a
  clearer release line to roll back to.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- Release tag `v3.0.0`
- `labkit.ui` `3.1.3 -> 3.2.0`
- `labkit_launcher` `1.1.2 -> 1.1.3`

- Improved UI diagnostics and validation documentation.
- Published the v3.0.0 release line around UI diagnostics, validation docs, and
  duplicate CI avoidance.

## User and data impact

- Maintainers got better evidence when app callbacks failed, and users got a
  clearer release line to roll back to.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commits `21eff4dc` and release tag commit `349a7549`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
