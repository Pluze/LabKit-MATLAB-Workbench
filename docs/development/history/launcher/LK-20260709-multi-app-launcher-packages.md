# Multi-app launcher packages

```labkit-change
schema: 1
id: LK-20260709-multi-app-launcher-packages
date: 2026-07-09
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.2.7 -> 1.3.0`
```

## Context

- Related LabKit apps can be distributed together without shipping unrelated
  apps or manually combining separate packages.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit_launcher` `1.2.7 -> 1.3.0`
- Project deployment tooling, multi-app bundle support.

- Added an independent `Package` checkbox column to the launcher app table so
  users can choose multiple apps without changing the row selected for Open or
  Debug.
- `Package Checked` and `Checked P-code` now create one zip containing every
  checked app, one direct entry file per app, and a multi-app manifest.
- Kept single-app package names, result fields, and manifest schema compatible
  when only one app is supplied to `packageLabKitApp`.

## User and data impact

- Related LabKit apps can be distributed together without shipping unrelated
  apps or manually combining separate packages.

## Compatibility and migration

- Existing direct calls that package one app continue to produce the original
  single-app package contract.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Mainline commit `8a23a52`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
