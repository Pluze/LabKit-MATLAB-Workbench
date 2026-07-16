# File-panel layout stabilization

```labkit-change
schema: 1
id: LK-20260630-file-panel-layout-stabilization
date: 2026-06-30
type: fix
compatibility: compatible
component: `labkit.ui` | `3.2.3 -> 3.2.4`
component: `labkit.ui` | `3.2.4 -> 3.2.5`
```

## Context

- File-heavy app workflows became easier to scan and less layout-fragile.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.ui` `3.2.3 -> 3.2.5`

- Stabilized and compacted single file-panel layout.

## User and data impact

- File-heavy app workflows became easier to scan and less layout-fragile.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commits `7f8df1cd` and `02b2f1b6`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
