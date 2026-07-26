# Runtime diagnostics and workflow repair converge on one product path

```labkit-change
id: LK-20260726-runtime-diagnostics-and-workflow-repair
date: 2026-07-26
sequence: 159
type: feat
compatibility: breaking
component: `labkit_launcher` | `1.6.0 -> 1.7.0`
component: `labkit.app` | `1.2.4 -> 2.0.0`
component: `labkit.dta` | `2.0.3 -> 3.0.0`
component: `labkit.image` | `2.0.2 -> 2.0.3`
component: `labkit_DICPostprocess_app` | `1.5.1 -> 1.6.0`
component: `labkit_DICPreprocess_app` | `1.6.1 -> 1.7.0`
component: `labkit_ChronoOverlay_app` | `1.5.1 -> 1.6.0`
component: `labkit_CIC_app` | `1.5.1 -> 1.6.0`
component: `labkit_CSC_app` | `1.5.1 -> 1.6.0`
component: `labkit_EIS_app` | `1.5.2 -> 1.6.0`
component: `labkit_VTResistance_app` | `1.5.1 -> 1.6.0`
component: `labkit_GaitAnalysis_app` | `2.1.1 -> 2.2.0`
component: `labkit_BatchImageCrop_app` | `1.8.1 -> 1.9.0`
component: `labkit_CurvatureMeasurement_app` | `1.5.1 -> 1.6.0`
component: `labkit_FLIRThermal_app` | `1.5.1 -> 1.6.0`
component: `labkit_FocusStack_app` | `1.6.1 -> 1.7.0`
component: `labkit_ImageEnhance_app` | `1.7.1 -> 1.8.0`
component: `labkit_ImageMatch_app` | `1.7.1 -> 1.8.0`
component: `labkit_VideoMarker_app` | `1.6.1 -> 1.7.0`
component: `labkit_FigureStudio_app` | `0.6.5 -> 0.7.0`
component: `labkit_NerveResponseAnalysis_app` | `1.5.1 -> 1.6.0`
component: `labkit_ResponseReviewStats_app` | `1.5.1 -> 1.6.0`
component: `labkit_RHSPreview_app` | `1.5.1 -> 1.6.0`
component: `labkit_TTestWizard_app` | `1.2.0 -> 1.3.0`
component: `labkit_ECGPrint_app` | `1.5.1 -> 1.6.0`
scope: Always-on session diagnostics and semantic App events
scope: Clean startup and explicit synthetic-input generation
scope: Launcher repair boundary and preserved product interaction
scope: Batch Crop native ROI interaction and preview resolution
scope: Explicit DTA units and EIS impedance display units
```

## Context

Debug launching had combined synthetic data, diagnostic persistence, and App
startup into one mode, while ordinary incidents often left too little useful
history. App-owned Log tabs and status/error adapters competed with a partial
framework recorder. Batch Crop also exposed the practical consequence of
testing construction without native interaction: its ROI could be visible yet
fail to respond, and ordinary images were unnecessarily downsampled.

The root Launcher had simultaneously accumulated installed-product behavior,
repair implementation, and maintenance-tool logic in one rescue file. DTA
inputs also carried ambiguous unit inference into downstream electrochemistry
workflows.

## Decision and rationale

Every normal App launch now owns one clean Runtime session with an always-on,
privacy-bounded event journal. Runtime instruments framework operations;
Apps add stable semantic events through `CallbackContext.log`. Trace capture,
session viewing, and bundle export are runtime tools, while synthetic input
generation is a separate explicit developer action that never loads its output
or changes the open project.

The public App SDK advances to 2.0 because launch diagnostic options and the
old status, error, checkpoint, count, recorder, and debug-sample contracts were
removed rather than kept as misleading compatibility aliases. Each migrated
App requires `labkit.app >=2 <3`.

The root Launcher remains a small self-contained repair entry. The installed
launcher keeps the established catalog, status, App information, double-click
launch, version browsing, and visual identity, while independent maintenance
operations live under `tools/`.

## Changes

- Added canonical session events, durable bounded journals, active-session
  leases, degradation reporting, operation/result versus rollback semantics,
  a live session viewer, trace control, and diagnostic bundle export.
- Migrated all public Apps to semantic user/developer events, removed duplicate
  Log tabs, and exposed explicit anonymous synthetic-input generation from the
  ordinary Tools menu.
- Kept default launches data-free and action-free; hidden GUI tests now own
  their visibility fixture instead of relying on a test tag.
- Restored Batch Crop ROI body drag, center drag, and click-to-place behavior
  through managed native interaction, while preserving the viewport and using
  full-resolution previews unless an explicit high-resolution budget applies.
- Made DTA item units explicit, rejected unknown pulse modes, and added EIS
  impedance display choices from milliohms through megohms with kilohms as the
  default.
- Split Launcher rescue, installed composition, version management, cleanup,
  and documentation responsibilities without removing product capabilities.

## User and data impact

Users can diagnose a problem after it occurs in an ordinary session, export a
sanitized history, and deliberately generate anonymous reproduction inputs
without restarting in a special mode. App status remains concise, while
developer detail is available through Diagnostics. Existing scientific source
files are not rewritten.

Batch Crop keeps source resolution for ordinary images and provides responsive
native ROI editing. EIS changes only display and export scaling selected by
the user; calculations retain canonical ohms. Launcher repair remains explicit
and never downloads or replaces files merely because it was opened.

## Compatibility and migration

`labkit.app` 2.0 intentionally removes the former launch/debug and diagnostic
adapter APIs. App source using those APIs must migrate to `BuildSyntheticSample`
and semantic `CallbackContext.log` events. Saved App project schemas and their
declared migrations are unchanged.

`labkit.dta` 3.0 replaces ambiguous numeric unit inference with explicit unit
metadata. Consumers must use declared canonical values. `labkit.image` 2.0.3
removes library-owned default megapixel policy; Apps choose preview budgets
according to their own workflow.

## Validation

Focused framework suites cover event schema, RNG preservation, operation
outcomes, multi-process leases, privacy allowlists, projection degradation,
viewer behavior, bundle export, Runtime instrumentation, and repository
architecture. All 63 public hidden native App smoke cases pass. Every migrated
App family has focused workflow coverage, including Batch Crop native ROI and
preview-resolution contracts, EIS units, DTA parity, Launcher dispatch/repair,
and synthetic-input state neutrality.

## Evidence

The `debug-repair` branch contains purpose-based implementation and focused-test
commits. Final evidence is the branch-review validation result, pull-request
CI, merged-main CI, and developer-led manual checks recorded in the pull
request.

## Known limitations and follow-up

Hidden GUI tests do not establish pointer feel, dialog usability, visual
quality, or the usefulness and privacy of exported incident bundles. Those
remain explicit manual acceptance gates before merge.
