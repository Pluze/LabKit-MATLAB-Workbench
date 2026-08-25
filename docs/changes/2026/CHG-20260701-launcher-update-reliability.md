# Launcher update reliability

```labkit-change
id: CHG-20260701-launcher-update-reliability
date: 2026-07-01
type: fix
compatibility: compatible
component: labkit_launcher | 1.1.3 -> 1.1.5
```

## Why

The self-contained launcher could install a ZIP release, but the replacement path performed more filesystem work than necessary and duplicated logic for locating, unpacking, and replacing the workbench. Slow replacement made a successful update look stalled; duplicated recovery paths made failures harder to reason about.

### Accepted choice

Minimize the files touched during an update and give ZIP replacement one straight-line implementation. Preserve the existing installation until the download and unpack steps have produced a usable replacement.

## What changed

- Sped up launcher zip updates.
- Simplified launcher zip replacement.

## Impact

ZIP updates completed with less waiting and fewer intermediate operations. A failure before replacement left the existing checkout available, while a successful update continued to present the same launcher entry point.

## Compatibility and limits

Existing managed installations remained updateable. The replacement algorithm changed internally and did not require users to reinstall a working checkout.

### Remaining limits

The updater still depended on the release artifact being trustworthy. Later release work added stronger tag-to-asset verification and update diagnostics.
