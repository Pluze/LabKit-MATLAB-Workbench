# Protected image enhancement workflows

```labkit-change
schema: 1
id: LK-20260629-protected-image-enhancement-workflows
date: 2026-06-29
type: feat
compatibility: compatible
component: `labkit_ImageEnhance_app` | `1.2.2 -> 1.3.0`
component: `labkit_ImageMatch_app` | `1.2.1 -> 1.3.0`
scope: historical project evolution
```

## Context

The existing appearance adjustments could change a subject together with its
background. Image Enhance and Image Match needed modes that protected subject
detail while correcting bright backgrounds and tone.

## Decision and rationale

Add subject-preserving enhancement and protected tone matching as explicit
methods with their own parameters, descriptions, and tests. Keep these methods
inside the image apps because they encode workflow-specific decisions rather
than generic image primitives.

## Changes

- Image Enhance `1.2.2 -> 1.3.0`
- Image Match `1.2.1 -> 1.3.0`

- Added Subject-preserving enhance to Image Enhance.
- Added Protected tone to Image Match.
- Added calculation and GUI coverage for both methods.

## User and data impact

Users could brighten or normalize a background with less change to the main
subject. The new methods were optional; existing histories and other matching
methods retained their previous behavior.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

The carrying commit added focused Image Enhance and Image Match unit tests and
updated both GUI workflow tests. The exact historical test command was not
recorded.

## Evidence

- Main commit `1768dd57`.

## Known limitations and follow-up

The protected methods reduce unwanted subject changes but cannot infer semantic
foreground perfectly. Their result still requires visual review.
