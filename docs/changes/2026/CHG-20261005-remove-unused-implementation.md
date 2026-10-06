# Simplify App state, implementation, and behavior tests

```labkit-change
id: CHG-20261005-remove-unused-implementation
date: 2026-10-05
type: refactor
compatibility: compatible
component: labkit.app
component: labkit_DICPostprocess_app | 1.7.3 -> 1.7.4
component: labkit_DICPreprocess_app | 1.8.2 -> 1.8.3
component: labkit_ChronoOverlay_app | 1.7.2 -> 1.7.3
component: labkit_CIC_app | 1.7.2 -> 1.7.3
component: labkit_CSC_app | 1.7.2 -> 1.7.3
component: labkit_EIS_app | 1.9.0 -> 1.9.1
component: labkit_VTResistance_app | 1.7.1 -> 1.7.2
component: labkit_GaitAnalysis_app | 3.0.3 -> 3.0.4
component: labkit_BatchImageCrop_app | 1.10.4 -> 1.10.5
component: labkit_CurvatureMeasurement_app | 1.7.2 -> 1.7.3
component: labkit_FLIRThermal_app | 1.7.2 -> 1.7.3
component: labkit_FocusStack_app | 1.9.1 -> 1.9.2
component: labkit_ImageEnhance_app | 1.9.3 -> 1.9.4
component: labkit_ImageMatch_app | 1.9.2 -> 1.9.3
component: labkit_VideoMarker_app | 1.9.0 -> 1.9.1
component: labkit_FigureStudio_app | 0.10.1 -> 0.10.2
component: labkit_NerveResponseAnalysis_app | 1.7.2 -> 1.7.3
component: labkit_ResponseReviewStats_app | 1.7.2 -> 1.7.3
component: labkit_RHSPreview_app | 1.7.2 -> 1.7.3
component: labkit_TTestWizard_app | 1.5.1 -> 1.5.2
component: labkit_ECGPrint_app | 2.2.1 -> 2.2.2
component: repository
```

## Why

Unused internal interfaces, duplicate implementation, and tests tied to incidental bookkeeping made maintenance larger than the supported behavior required. Two independently maintained Image Match method lists also disagreed: menu labels without a calculation branch silently selected Balanced, while documented modes could be reset during a settings change.

## What changed

The SDK removes uncalled runtime and dialog helpers, impossible struct-field validation, and unused native sizing options. Source-list reconciliation is stateless, validates each input collection at its boundary, and preserves role order and stable identities through direct collection operations. Presentation reads those values directly without a callback through the Runtime, and file-selection commits own index validation. Runtime construction no longer rechecks state already validated by its constructor boundary; resources retain values and cleanup callbacks without a duplicate key field. Figure Studio keeps its documented axes export entrypoint as the implementation owner and retires an unused canvas layout and derived style-provenance helper. Batch Crop fixtures construct ordinary task values instead of shipping a test-only factory. CSC plot payloads contain drawing data without unused logging fields. Documentation renderers share one private HTML-escaping implementation.

Image Match controls and settings validation use one list of the six implemented matching modes. The formulas and strength semantics of those modes are unchanged. Test planning drops an always-false fallback field, and maintenance tests protect discovery and selection behavior without copying current method inventories. Current manuals and scoped agent guidance describe the supported paths without duplicate package lists or maintenance checklists.

App initialization constructs defaults directly. Focus Stack owns one current fusion result and clears it on source or parameter changes; unused saved-summary and registration mirrors are retired. Focus Stack, Gait Analysis, and Curvature execute their analysis from current inputs without serialized run fingerprints or task wrappers. Image Enhance rebuilds previews at its existing edit boundaries without parallel label-based cache keys. Batch Crop resolves task paths from source records instead of maintaining a second path array. Export-only bookkeeping with no runtime reader is removed; export tests inspect the chosen files and preserve content checks.

CI configuration checks parse YAML and execute the actual gate against controlled success and failure outcomes instead of maintaining MATLAB assertions for workflow formatting, step labels, and checklist counts. Scientific comparisons, user-visible workflow outcomes, and exported files remain the validation targets.

Image Enhance and Image Match invalidate the visible manifest through the existing source-refresh lifecycle, without retaining a second export payload or comparing copied source identities. FLIR Thermal retains only its displayed manifest path. Curvature delegates calibration normalization to the existing SDK capability, preserving its App input forms and numerical semantics. Export manifest construction uses direct table columns rather than parallel preallocated arrays and assignment loops. Private source comments retain non-obvious behavior and assumptions; repeated file/package ownership headers are removed.

Compiled definitions own callback resolution and the interaction declaration list shared with the native adapter. Runtime no longer rediscovers callbacks by traversing layout configuration, and the adapter no longer rebuilds an interaction inventory. Busy labels resolve target identifiers containing double underscores correctly. The source-text App invocation scanner is retired; every App still requires an executable native core journey with outcome assertions. Internal architecture guidance preserves responsibilities and observable lifecycle behavior without making class names or file decomposition compatibility requirements.

Diagnostics now has one live-history retention owner. The viewer projects current stream snapshots, retaining only the records associated with displayed rows; duplicate byte accounting, trimming, and copied health state are removed. The stream publishes history after enforcing its limits, preventing timer readers from observing an over-limit intermediate value. Journal health notifications belong to the writer, without a separate projection adapter or redundant health-schema validation. Runtime accesses its existing recorder directly, and viewer refresh reads in-memory health counters without reconstructing the disk manifest. Event creation, persistence, and archive reading share the canonical record schema. Runtime construction has one platform-selecting entrypoint. Tests use journal-guarded construction seams; the test-only production JournalRoot option, argument-source parser, and parser-only assertions are retired in favor of executable missing/empty-journal checks; the single journal-directory policy no longer requires a generic artifact store.

## Impact

Source, tests, and documentation have fewer parallel representations to maintain. Image Match users can select each documented mode and retain that choice in the applied history. File-list reconciliation continues to preserve other source roles, repeated paths with distinct IDs, and column-shaped collections.

## Compatibility and limits

Public facade signatures, Figure Studio's documented export entrypoint, App saved-data and export formats, and scientific algorithms remain unchanged. Image Match has no saved task archive; the previously unrecognized menu labels did not identify separate algorithms. Internal helpers and test artifact bookkeeping are not compatibility interfaces. Automated hidden-GUI evidence does not establish pointer feel, real-data suitability, or physical hardware behavior.
