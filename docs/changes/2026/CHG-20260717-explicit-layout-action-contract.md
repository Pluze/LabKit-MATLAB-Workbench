# Explicit layout action contract

```labkit-change
id: CHG-20260717-explicit-layout-action-contract
date: 2026-07-17
type: refactor
compatibility: compatible
component: labkit_DICPostprocess_app | 1.4.5 -> 1.4.6
component: labkit_DICPreprocess_app | 1.5.6 -> 1.5.7
component: labkit_ChronoOverlay_app | 1.4.6 -> 1.4.7
component: labkit_CIC_app | 1.4.6 -> 1.4.7
component: labkit_CSC_app | 1.4.6 -> 1.4.7
component: labkit_EIS_app | 1.4.6 -> 1.4.7
component: labkit_VTResistance_app | 1.4.6 -> 1.4.7
component: labkit_GaitAnalysis_app | 2.0.6 -> 2.0.7
component: labkit_BatchImageCrop_app | 1.7.5 -> 1.7.6
component: labkit_CurvatureMeasurement_app | 1.4.5 -> 1.4.6
component: labkit_FLIRThermal_app | 1.4.5 -> 1.4.6
component: labkit_FocusStack_app | 1.5.4 -> 1.5.5
component: labkit_ImageEnhance_app | 1.6.5 -> 1.6.6
component: labkit_ImageMatch_app | 1.6.5 -> 1.6.6
component: labkit_VideoMarker_app | 1.5.5 -> 1.5.6
component: labkit_FigureStudio_app | 0.2.7 -> 0.2.8
component: labkit_NerveResponseAnalysis_app | 1.4.5 -> 1.4.6
component: labkit_ResponseReviewStats_app | 1.4.5 -> 1.4.6
component: labkit_RHSPreview_app | 1.4.5 -> 1.4.6
component: labkit_ECGPrint_app | 1.4.5 -> 1.4.6
```

## Why

Every public App layout carried the same local `callbackValue` helper. The helper returned an empty value when a callback field was absent, so a misspelled or unregistered action could survive startup as a control that silently did nothing. Twenty copies also obscured that Runtime already creates the complete callback table from each App definition.

### Accepted choice

Layouts reference Runtime-generated callbacks directly. MATLAB field access therefore validates the action ID while the data-only layout is built. Runtime remains the single callback-adapter owner; Apps own only their semantic action registries and layout references.

## What changed

- Removed the duplicated callback fallback from all 20 public App layouts.
- Replaced static lookups with direct `callbacks.actionId` references and kept dynamic field access only in three small controls whose action names are supplied by the surrounding layout.
- Added a fleet-wide contract that creates every App definition and layout with the Runtime callback inventory.
- Updated direct neurophysiology layout tests to supply explicit callbacks derived from their action registries.

## Impact

Correctly registered controls behave as before. A broken App definition now fails during layout construction instead of presenting an inert control. No scientific calculation, project payload, saved file, or interaction semantics changed.

## Compatibility and limits

No project migration is required. This is an App-development contract tightening: custom layouts must register every referenced semantic action.

### Remaining limits

This change deliberately does not merge short semantic actions or dynamic control helpers merely to reduce line count. Those remain candidates only when a repeated behavior has one stable, domain-neutral owner.
