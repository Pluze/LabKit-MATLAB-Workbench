# v2.3.2 and v2.3.3: preview performance and release contracts

```labkit-change
schema: 2
id: LK-20260623-v2-3-performance-and-release-contracts
date: 2026-06-23
sequence: 9
type: fix
compatibility: compatible
scope: historical project evolution
```

## Context

By v2.3.1, app discovery and image interaction were substantially better, but
users could still experience redundant preview processing and unstable axes
limits. Separately, a working release download was not sufficient evidence that
the downloaded launcher came from the intended tag.

## Decision and rationale

Separate preview computation from rendering so an interaction does not repeat
scientific or image processing unnecessarily. Stabilize axes behavior at the
app boundary, then make release assets reproducible and add facade contract
checks that describe which library calls apps may rely on.

## Changes

- Stabilized EIS zoom on logarithmic axes and reset plot limits when coordinate
  choices changed.
- Reduced repeated image preview processing and separated preview preparation
  from display updates.
- Documented the boundary between preview state and exported results.
- Added pixel-radius controls for scale previews.
- Required release assets to be reproduced from their Git tag.
- Improved GitHub onboarding and issue templates.
- Added facade contract checks and hid windows created by automated GUI tests.

## User and data impact

Image apps responded more quickly when controls changed without requiring new
processing. EIS navigation became more predictable, and scale previews exposed
their pixel radius directly. Release users gained a stronger link between the
published tag and the launcher they downloaded.

The preview/export separation clarified that a faster display refresh must not
silently change exported numerical or spatial results.

## Compatibility and migration

The changes corrected existing v2 behavior without introducing a new user data
format. Tags `v2.3.2` and `v2.3.3` point to `29669ca6` and `a7e7dfb1`,
respectively.

## Validation

Focused EIS and image-preview tests accompanied the fixes. Release guidance
added tag-derived asset checks, and facade tests checked supported app-to-
library calls. Automated GUI windows were hidden to reduce test interference.

## Evidence

- EIS axes fixes `6c8e6540`, `579bc56a`.
- Preview processing separation `cc65e844`, `2369ffd3`.
- Preview/export contract and scale controls `d0d46f6e`, `29669ca6`.
- Reproducible release and onboarding `1832f46a` through `0c5243a9`.
- Facade and GUI-test contracts `a25b79f9`, `20ea41b8`.

## Known limitations and follow-up

Component-specific version metadata was introduced only after these releases,
so the early record relies on repository tags and commit evidence. Later
history pages can name both the repository release and the affected component
version.
