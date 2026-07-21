# UI diagnostics and release v3.0.0

```labkit-change
id: LK-20260629-ui-diagnostics-and-release-v3-0-0
date: 2026-06-29
sequence: 17
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.1.2 -> 1.1.3`
component: `labkit.ui` | `3.1.3 -> 3.2.0`
scope: UI diagnostics and release v3.0.0
```

## Context

The diagnostic work completed during the 3.x UI cycle needed a stable release
checkpoint, clearer validation documentation, and CI behavior that would not
run duplicate workflows for the same change.

## Decision and rationale

Publish the UI diagnostic improvements as `v3.0.0`, document how they are
validated, and avoid redundant CI triggers. Keep the release compatible with
the app data produced by the preceding 2.x workbench releases.

## Changes

- Release tag `v3.0.0`
- `labkit.ui` `3.1.3 -> 3.2.0`
- `labkit_launcher` `1.1.2 -> 1.1.3`

- Improved UI diagnostics and validation documentation.
- Published the v3.0.0 release line around UI diagnostics, validation docs, and
  duplicate CI avoidance.

## User and data impact

Users gained a named release to install or restore, while failure reports
contained better callback context. Project and scientific result formats did
not change in this release record.

## Compatibility and migration

The v3.0.0 release retained the preceding app data formats. Users could update
or roll back the workbench without converting saved scientific results.

## Validation

Commit `21eff4dc` carried the diagnostic and validation changes; tag commit
`349a7549` published `v3.0.0`. Exact historical local commands were not
recorded.

## Evidence

- Main commits `21eff4dc` and release tag commit `349a7549`.

## Known limitations and follow-up

This record marks the release boundary; individual diagnostic mechanics are
described in their earlier component history records.
