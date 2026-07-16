# Launcher update reliability

```labkit-change
schema: 2
id: LK-20260701-launcher-update-reliability
date: 2026-07-01
sequence: 25
type: fix
compatibility: compatible
component: `labkit_launcher` | `1.1.3 -> 1.1.4`
component: `labkit_launcher` | `1.1.4 -> 1.1.5`
```

## Context

The self-contained launcher could install a ZIP release, but the replacement
path performed more filesystem work than necessary and duplicated logic for
locating, unpacking, and replacing the workbench. Slow replacement made a
successful update look stalled; duplicated recovery paths made failures harder
to reason about.

## Decision and rationale

Minimize the files touched during an update and give ZIP replacement one
straight-line implementation. Preserve the existing installation until the
download and unpack steps have produced a usable replacement.

## Changes

- `labkit_launcher` `1.1.3 -> 1.1.5`

- Sped up launcher zip updates.
- Simplified launcher zip replacement.

## User and data impact

ZIP updates completed with less waiting and fewer intermediate operations. A
failure before replacement left the existing checkout available, while a
successful update continued to present the same launcher entry point.

## Compatibility and migration

Existing managed installations remained updateable. The replacement algorithm
changed internally and did not require users to reinstall a working checkout.

## Validation

Both commits extended `LauncherGuiTest` around download, replacement, and
recovery behavior. The exact historical commands were not recorded.

## Evidence

- Main commits `ebf86cf2` and `becf9391`.

## Known limitations and follow-up

The updater still depended on the release artifact being trustworthy. Later
release work added stronger tag-to-asset verification and update diagnostics.
