# Simplified runtime and workflow ownership

```labkit-change
id: LK-20260819-runtime-and-workflow-simplification
date: 2026-08-19
sequence: 185
type: refactor
compatibility: compatible
component: `labkit.dta` | `3.1.0 -> 3.1.1`
component: `labkit.mark10` | `1.0.0 -> 1.0.1`
component: `labkit_DICPreprocess_app` | `1.7.2 -> 1.7.3`
component: `labkit_CIC_app` | `1.6.2 -> 1.6.3`
component: `labkit_EIS_app` | `1.6.2 -> 1.6.3`
component: `labkit_VTResistance_app` | `1.6.2 -> 1.6.3`
component: `labkit_Mark10Monitor_app` | `1.0.0 -> 1.0.1`
component: `labkit_GaitAnalysis_app` | `2.2.2 -> 2.2.3`
component: `labkit_BatchImageCrop_app` | `1.9.3 -> 1.9.4`
component: `labkit_CurvatureMeasurement_app` | `1.6.2 -> 1.6.3`
component: `labkit_FLIRThermal_app` | `1.6.2 -> 1.6.3`
component: `labkit_FocusStack_app` | `1.7.2 -> 1.7.3`
component: `labkit_ImageEnhance_app` | `1.8.2 -> 1.8.3`
component: `labkit_ImageMatch_app` | `1.8.2 -> 1.8.3`
component: `labkit_NerveResponseAnalysis_app` | `1.6.1 -> 1.6.2`
component: `labkit_ResponseReviewStats_app` | `1.6.1 -> 1.6.2`
component: `labkit_RHSPreview_app` | `1.6.2 -> 1.6.3`
scope: App workflow simplification
scope: DTA parser ownership
scope: Mark-10 callback and sampling state
```

## Context

Repository-wide simplification found private helpers that duplicated direct MATLAB operations, retained retired workflow layers, or split one parser or callback responsibility across unnecessary files. Keeping those paths increased dependency and test-maintenance cost without preserving an independent user contract.

## Decision and rationale

The affected Apps now keep straightforward workflow glue at its natural caller, while the DTA and Mark-10 facades retain their existing public surfaces with fewer internal ownership seams. This favors visible fixed symbol calls and one clear state transition over compatibility-only or speculative helper layers.

## Changes

Unused App helpers and their implementation-shaped tests were removed, repeated DTA table-section parsing was consolidated, and Mark-10 sampling and App callbacks were reduced to their direct owners. Gait step review composition and several result or presentation paths now express the same supported workflow with less intermediate state and dispatch code.

## User and data impact

Entrypoints, controls, supported inputs, calculations, exports, project data, and facade call syntax remain available. Existing projects and laboratory data require no conversion; the changes reduce internal code and do not introduce a new runtime dependency.

## Compatibility and migration

The release is compatible within each component's existing major-version range. No saved-data migration, API rename, optional Toolbox, Java, Python, Conda, or third-party runtime is required.

## Validation

Source-aligned specifications cover the retained parsing, sampling, scientific result, presentation, App definition, and repository architecture contracts. Final integration validation also runs the changed-path local gate and the complete required pull-request matrix on supported MATLAB and operating-system boundaries.

## Evidence

The net branch diff was audited from the mainline baseline, and each affected component advances by one direct patch transition. Code analysis reports no issues, suppressions, compatibility recommendations, or unreviewed secondary-runtime calls.

## Known limitations and follow-up

No known compatibility limitation or follow-up remains for this simplification.
