# Version metadata baseline

```labkit-change
schema: 1
id: LK-20260623-version-metadata-baseline
date: 2026-06-23
type: feat
compatibility: compatible
introduced: `labkit_launcher` | `1.0.0`
component: `labkit.ui` | `2.1.0 -> 2.2.0`
introduced: `labkit_DICPostprocess_app` | `1.0.0`
introduced: `labkit_DICPreprocess_app` | `1.0.0`
introduced: `labkit_ChronoOverlay_app` | `1.0.0`
introduced: `labkit_CIC_app` | `1.0.0`
introduced: `labkit_CSC_app` | `1.0.0`
introduced: `labkit_EIS_app` | `1.0.0`
introduced: `labkit_VTResistance_app` | `1.0.0`
introduced: `labkit_BatchImageCrop_app` | `1.0.0`
introduced: `labkit_CurvatureMeasurement_app` | `1.0.0`
introduced: `labkit_FocusStack_app` | `1.0.0`
introduced: `labkit_ImageEnhance_app` | `1.0.0`
introduced: `labkit_ImageMatch_app` | `1.0.0`
introduced: `labkit_NerveResponseAnalysis_app` | `1.0.0`
introduced: `labkit_ResponseReviewStats_app` | `1.0.0`
introduced: `labkit_RHSPreview_app` | `1.0.0`
introduced: `labkit_ECGPrint_app` | `1.0.0`
```

## Context

- This is the first point where app and launcher versions became first-class
  user-facing metadata.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- Release tag `v2.4.0`
- `labkit_launcher` `1.0.0`
- All supported apps `1.0.0`
- `labkit.ui` `2.1.0 -> 2.2.0`

- Added app and launcher version metadata.
- Added versioned titles, lightweight version requests, launcher catalog version
  display, and version guardrails.

## User and data impact

- This is the first point where app and launcher versions became first-class
  user-facing metadata.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `d70c2607`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
