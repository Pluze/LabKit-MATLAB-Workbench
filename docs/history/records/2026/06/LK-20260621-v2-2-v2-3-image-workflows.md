# v2.2 to v2.3.1: self-contained launch and image workflow refinement

```labkit-change
schema: 2
id: LK-20260621-v2-2-v2-3-image-workflows
date: 2026-06-21
sequence: 8
type: feat
compatibility: compatible
scope: historical project evolution
```

## Context

The launcher and updater existed, but installation still assumed repository
context. At the same time, ordinary image work exposed small but costly
interaction problems: selecting several files, preserving zoom while placing a
marker, padding a crop without shifting its source coordinates, or returning
to duplicate-crop mode after editing scale.

## Decision and rationale

Make the launcher usable as a self-contained entry artifact and refine the
high-frequency image workflows in place. These releases favored fewer steps
and stable spatial state over adding more general-purpose dialogs or toolbars.

## Changes

- Made the launcher self-contained and added an update button backed by the
  release updater.
- Appended file-panel selections and added multi-file choose-and-load behavior.
- Improved Image Match speed and separated its reference input from moving
  images.
- Preserved Batch Crop source coordinates when padding, reduced padding seams,
  and refined the padding workflow.
- Added physical scale mode to Batch Crop and restored scale and duplicate-task
  interactions after edits.
- Preserved image-tool zoom while placing or editing overlays.
- Hardened image-tool ownership and changed the README to present the launcher
  as the primary user entry.

## User and data impact

Users could begin from a compact launcher, select several files in one action,
and edit image overlays without losing their current view. Batch Crop gained
physical scaling while retaining the relationship between the visible crop and
the source image.

Padding and scale metadata affected exported crop interpretation, so regression
work explicitly protected source coordinates and resumed interaction modes.

## Compatibility and migration

The changes were compatible additions and fixes to the v2 workflows. Release
tags identify the incremental baselines: `v2.2.0` at `c904baca`, `v2.3.0` at
`f2ed23c2`, and `v2.3.1` at `83d03e7a`.

## Validation

Focused tests covered path-list cleanup, Batch Crop scale and padding
contracts, preview interactions, and image-tool ownership. The exact command
for each historical commit was not recorded.

## Evidence

- Self-contained launcher and updater button `a1938db8`, `c904baca`.
- File selection and Image Match work `5aa10909`, `471b79c2`, `ebdbf9db`.
- Batch Crop padding `54c8fe43` through `f2ed23c2`.
- Zoom and physical scale `632191b9` through `2b9690fc`.
- Ownership hardening and primary launcher guidance `8328248a`, `83d03e7a`.

## Known limitations and follow-up

Some previews still repeated expensive processing, EIS log-axis navigation was
fragile, and the release process did not yet prove that downloadable artifacts
matched their tags. v2.3.2 and v2.3.3 addressed those issues.
