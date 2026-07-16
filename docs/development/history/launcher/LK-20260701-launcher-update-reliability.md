# Launcher update reliability

```labkit-change
schema: 1
id: LK-20260701-launcher-update-reliability
date: 2026-07-01
type: fix
compatibility: compatible
component: `labkit_launcher` | `1.1.3 -> 1.1.4`
component: `labkit_launcher` | `1.1.4 -> 1.1.5`
```

## Context

- Updating the self-contained launcher became less fragile.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit_launcher` `1.1.3 -> 1.1.5`

- Sped up launcher zip updates.
- Simplified launcher zip replacement.

## User and data impact

- Updating the self-contained launcher became less fragile.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commits `ebf86cf2` and `becf9391`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
