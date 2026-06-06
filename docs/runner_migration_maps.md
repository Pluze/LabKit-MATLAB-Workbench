# Runner Migration Maps

This document is the Phase 1 operating map for oversized app runners. It turns
the current debt inventory into concrete responsibility maps so future changes
can reduce real coupling instead of moving large bodies of code into new large
helpers.

Current architecture rules live in `docs/architecture.md`. Validation routing
lives in `docs/testing.md`. This file only tracks current oversized runners and
their intended migration shape.

## Migration Standard

A runner is healthy when it owns orchestration only:

- launch and debug wiring
- GUI shell construction
- app state coordination
- callback registration
- alerts and user-facing log wording
- refresh ordering

The runner should not own deterministic calculations, export table schemas,
parser/import option normalization, result summary construction, axis-value
generation, or local copies of behavior that already exists in an app-owned
package.

Every extraction from a runner must satisfy all of these:

- the real GUI path calls the extracted helper
- the helper has a direct unit test when it is not pure UI construction
- the public app launch command and app behavior stay unchanged
- app-specific workflow logic stays under the owning app tree
- no new `private` runner, `*Workflow.m`, or string-dispatch layer is created

## Current Oversized Runner Inventory

| Runner | Family | Current status | First useful reduction |
| --- | --- | --- | --- |
| `apps/electrochem/cic/+cic/+ui/runApp.m` | electrochem | App-owned package owns CIC computation, table/export helpers, current-file summary text, and plot request preparation. Runner still owns axes drawing and annotation side effects. | Stop shrinking unless a future deterministic view-model appears; otherwise move to the next oversized runner. |
| `apps/electrochem/csc/+csc/+ui/runApp.m` | electrochem | App-owned `+ops` and small `+view` helpers exist, including trim overlay, comparison readout, and plot request preparation. Runner still owns callback orchestration and axes drawing. | Keep shrinking only if another deterministic view-model appears; otherwise move to the next oversized runner. |

## `apps/electrochem/cic/+cic/+ui/runApp.m`

### Current Responsibility Map

| Responsibility | Current location | Target owner |
| --- | --- | --- |
| Window preset application and UI callback sequencing | runner callbacks | runner |
| DTA file/folder dialogs and session mutation | runner callbacks plus `labkit.dta` facade | runner, later app `+io` only if normalization grows |
| CIC computation | `cic.ops.computeCIC` | already extracted |
| Batch table data | `cic.view.buildBatchTableData` | already extracted |
| CSV export | `cic.export.writeResultsCSV` | already extracted |
| Current-file summary strings and mode selection | `cic.view.buildCurrentSummary` | already extracted |
| Runner-facing CIC display unit normalization | `cic.view.displayUnit` | already extracted |
| Axis data selection and title/label decisions | `cic.view.plotRequest` | already extracted |
| Axes drawing, shading, limits, markers, annotations, and grid | runner plus existing `cic.view` axes annotation helpers | runner |
| UI-only axes reset, swap, refresh ordering | runner | runner |

### Next Extraction Target

CIC now has the obvious deterministic view helpers extracted. Stop shrinking the
CIC runner unless a future change exposes another directly testable view-model
that is not just axes or callback choreography.

Do not move `plotOneAxis` wholesale. It still mixes axes drawing, marker
creation, window shading, title/label assignment, and checkbox-driven UI
effects.

### Direct Test Target

Direct electrochem unit tests now cover current summary strings, display unit
scaling, selected CIC mode behavior, plot request preparation, batch table
formatting, compute behavior, and export contracts. Future CIC runner edits
should add direct tests only when new deterministic behavior is extracted.

### Exit Criteria

- Summary value construction is outside the runner.
- Plot request preparation is outside the runner.
- Runner still assigns values to UI handles and controls refresh order.
- GUI behavior and CSV/export schema are unchanged.

## `apps/electrochem/csc/+csc/+ui/runApp.m`

### Current Responsibility Map

| Responsibility | Current location | Target owner |
| --- | --- | --- |
| DTA file/folder dialogs and session mutation | runner callbacks plus `labkit.dta` facade | runner |
| CV/CT CSC computation | `csc.ops.computeCSC` | already extracted |
| Curve dropdown population and default X/Y selection | runner (`updateDropdowns`) plus `csc.view.defaultPlotSelections` | default selection already extracted; dropdown population stays runner |
| Charge/CSC display formatting | `csc.view.formatChargeAndCSC` | already extracted |
| Comparison readout and status text | `csc.view.comparisonReadout` | already extracted |
| Trim overlay preparation | `csc.view.trimOverlayData` | already extracted |
| Trim overlay cleanup and plotting | runner local `clearTrim`, `drawTrimOverlay` axes logic | runner |
| Top/bottom plot-data, label, and log preparation | `csc.view.plotRequest` | already extracted |
| Top/bottom axes drawing | runner with `labkit.ui.view.draw` | runner |
| Reload, clear, current item selection | runner | runner |

### Next Extraction Target

CSC now has the obvious deterministic view helpers extracted. Stop shrinking the
CSC runner unless a future change exposes another directly testable view-model
that is not just GUI callback choreography.

Do not move `plotTop`, `plotBottom`, or `refreshCompare` as one block. These
callbacks still mix axes drawing, UI handle updates, trim drawing, status labels,
and logging, and those side effects belong in the runner.

### Direct Test Target

Direct electrochem unit tests now cover CSC formatting, default selections, trim
overlay data, comparison readout, and plot request preparation. Future CSC
runner edits should extend those tests only when new deterministic behavior is
extracted.

### Exit Criteria

- Formatting and default-selection helpers are package-owned.
- Comparison readout and status preparation is package-owned.
- Trim overlay preparation is package-owned.
- Plot request preparation is package-owned.
- Runner still owns file/session callbacks and axes handle updates.
- No same-named local helper remains in `+ui/runApp.m` after extraction.

## Completed Wearable ECG Print Migration

ECG Print now lives under `apps/wearable/ecg_print/` with the public command
still named `labkit_ECGPrint_app`. App-owned helpers own import option
normalization, header preview, import status text, summary rows, segment export
table smoothing, peak-method mapping, waveform/template plot request
preparation, and app-specific control construction.

The remaining `ecg_print.ui.runApp` runner stays below the oversized-runner
threshold and owns orchestration: shell launch, callback order, state mutation,
axes drawing side effects, alerts, file dialogs, export side effects, log
wording, and debug launch wiring.

Direct wearable unit tests cover the extracted non-UI `+io`, `+view`,
`+export`, and `+ops` helpers with synthetic option values, recordings, state
structs, plot requests, and tables. GUI structural tests still cover launch and
layout only.

## Completed DIC Preprocess Migration

DIC Preprocess now lives under `apps/dic/dic_preprocess/` with the public
command still named `labkit_DICPreprocess_app`. The remaining
`dic_preprocess.ui.runApp` runner is below the oversized-runner threshold and
owns orchestration: callback ordering, app state coordination, alerts,
user-facing log wording, file-selection cancellation handling, and refresh
ordering.

App-owned helpers now carry the deterministic and mechanical responsibilities:

| Responsibility | Owner |
| --- | --- |
| Registration, crop geometry, false-color preview, and ROI mask geometry | `dic_preprocess.ops` |
| Summary/detail text, preview requests, mask-control enable state | `dic_preprocess.view` |
| Initial state, loaded-image assignment, undo snapshots, reset/restore transitions, mask canvas add/subtract | `dic_preprocess.state` |
| Image-file chooser, default save paths, current-image save dialog, ROI-mask save dialog | `dic_preprocess.io` |
| Current image-pair and mask PNG writes | `dic_preprocess.export` |
| App-specific control construction and preview/mask/crop UI handle mechanics | `dic_preprocess.ui` |

Direct DIC unit tests cover the non-UI `+ops`, `+view`, `+state`, `+io`, and
`+export` helpers with synthetic arrays, structs, paths, and temporary PNG
writes. GUI structural tests still cover launch, layout, callback wiring, and
preview runtime setup only; interactive point selection, crop dragging, mask
drawing, and visual output review remain manual GUI checks.

The remaining `apps/dic/private/` debt now belongs to DIC Postprocess helpers.
