# Debug sample packs

```labkit-change
schema: 1
id: LK-20260701-debug-sample-packs
date: 2026-07-01
type: feat
compatibility: compatible
component: `labkit.ui` | `3.3.1 -> 3.4.0`
component: `labkit_DICPostprocess_app` | `1.2.4 -> 1.3.0`
component: `labkit_DICPreprocess_app` | `1.2.2 -> 1.3.0`
component: `labkit_ChronoOverlay_app` | `1.2.1 -> 1.3.0`
component: `labkit_CIC_app` | `1.2.1 -> 1.3.0`
component: `labkit_CSC_app` | `1.2.1 -> 1.3.0`
component: `labkit_EIS_app` | `1.2.1 -> 1.3.0`
component: `labkit_VTResistance_app` | `1.2.1 -> 1.3.0`
component: `labkit_BatchImageCrop_app` | `1.5.1 -> 1.6.0`
component: `labkit_CurvatureMeasurement_app` | `1.2.4 -> 1.3.0`
component: `labkit_FLIRThermal_app` | `1.1.2 -> 1.2.0`
component: `labkit_FocusStack_app` | `1.3.0 -> 1.4.0`
component: `labkit_ImageEnhance_app` | `1.4.1 -> 1.5.0`
component: `labkit_ImageMatch_app` | `1.4.1 -> 1.5.0`
component: `labkit_NerveResponseAnalysis_app` | `1.2.4 -> 1.3.0`
component: `labkit_ResponseReviewStats_app` | `1.2.3 -> 1.3.0`
component: `labkit_RHSPreview_app` | `1.2.4 -> 1.3.0`
component: `labkit_ECGPrint_app` | `1.2.2 -> 1.3.0`
```

## Context

Debug reports could identify a failed callback, but reproducing the failure
still depended on the original laboratory file and the user's exact sequence
of actions. Those inputs were often unavailable to the person investigating
the report and were unsuitable as permanent test fixtures.

## Decision and rationale

Let every app create a small, synthetic sample pack that exercises its normal
loading path without containing laboratory data. Store the generated inputs
and expected output location beside the debug artifacts so a report can be
replayed from one self-contained folder.

## Changes

- `labkit.ui` `3.3.1 -> 3.4.0`
- All supported apps moved into the `1.3.x`, `1.4.x`, `1.5.x`, or `1.6.x`
  debug-sample-pack lines.

- Added app-owned debug sample packs.
- Added debug artifact sample and output folders.

## User and data impact

Debug mode gained a repeatable demonstration dataset for each supported app.
These packs were synthetic and intended for diagnosis, not as substitutes for
real experiment files or as reference scientific results.

## Compatibility and migration

The sample packs were additive debug assets. Existing app inputs and outputs
were unchanged, and no user file was copied into a pack.

## Validation

Commit `279befbc` added coverage tests for every app family, focused tests for
DIC, electrochem, image, RHS, and wearable sample writers, and layout checks
that exercised the generated packs.

## Evidence

- Main commit `279befbc`.

## Known limitations and follow-up

Sample packs were deliberately app-owned because each workflow knows which
inputs make a useful reproduction. They do not contain or archive a user's
original files.
