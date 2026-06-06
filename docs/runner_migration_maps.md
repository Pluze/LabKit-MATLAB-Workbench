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
| `apps/electrochem/cic/+cic/+ui/runApp.m` | electrochem | App-owned package exists, but runner still owns summary and plotting decisions. | Move summary/view-model helpers before touching callback flow. |
| `apps/electrochem/csc/+csc/+ui/runApp.m` | electrochem | App-owned `+ops` and small `+view` helpers exist, but runner still owns trim plotting and mixed comparison refresh. | Move trim overlay view-model helpers before changing load callbacks. |
| `apps/wearable/private/runECGPrintApp.m` | wearable | Private runner owns import options, analysis/export view models, smoothing, and plotting. | Create `apps/wearable/ecg_print/+ecg_print` and extract GUI-free import/view/export helpers first. |
| `apps/dic/private/runDICPreprocessApp.m` | DIC | Private runner coordinates image loading, registration, crop, mask editing, preview, state history, and exports. | Create a DIC preprocess migration map before code movement; extract deterministic state/view helpers first. |

## `apps/electrochem/cic/+cic/+ui/runApp.m`

### Current Responsibility Map

| Responsibility | Current location | Target owner |
| --- | --- | --- |
| Window preset application and UI callback sequencing | runner callbacks | runner |
| DTA file/folder dialogs and session mutation | runner callbacks plus `labkit.dta` facade | runner, later app `+io` only if normalization grows |
| CIC computation | `cic.ops.computeCIC` | already extracted |
| Batch table data | `cic.view.buildBatchTableData` | already extracted |
| CSV export | `cic.export.writeResultsCSV` | already extracted |
| Current-file summary strings | runner (`refreshResultsSummary`, `chronoControlModeText`, `bestSafeString`) | `cic.view` |
| CIC display unit/mode normalization | runner (`cicDisplayUnit`, `selectedCICValue`, `shortModeName`) | `cic.view` or `cic.state` |
| Axis data selection and title/label decisions | runner (`plotOneAxis`) plus existing `cic.view` annotations | `cic.view` |
| UI-only axes reset, swap, refresh ordering | runner | runner |

### Next Extraction Target

Extract a small `cic.view` helper for current-analysis summary rows and selected
CIC display value. This reduces runner-owned display logic without changing
loading, plotting, or export behavior.

Do not move `refreshResultsSummary` wholesale. Keep UI handle assignment in the
runner; move only the data/string preparation.

### Direct Test Target

Add or extend electrochem unit tests to call the new `cic.view` helper with
synthetic analysis structs. The test should verify current summary strings,
display unit scaling, and selected CIC mode behavior without launching the GUI.

### Exit Criteria

- Summary value construction is outside the runner.
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
| Trim overlay cleanup and plotting | runner local `clearTrim`, `refreshCompare` axes logic | `csc.view` for prepared overlay data or small draw helper |
| Top/bottom XY plotting | runner with `labkit.ui.view.draw` | runner until a clear reusable view model exists |
| Reload, clear, current item selection | runner | runner |

### Next Extraction Target

Extract a small trim overlay view-model helper from `refreshCompare`. It should
prepare cathodic/anodic overlay vectors and eligibility from plain values while
the runner keeps axes handles, plotting commands, status labels, and logging.

Do not move `refreshCompare` as one block. It mixes computation, UI handle
updates, trim drawing, status labels, and logging.

### Direct Test Target

Add or extend electrochem unit tests for trim overlay preparation with simple
vectors and selected axis names. Avoid launching the CSC app.

### Exit Criteria

- Formatting and default-selection helpers are package-owned.
- Trim overlay preparation is package-owned if it remains deterministic.
- Runner still owns file/session callbacks and axes handle updates.
- No same-named local helper remains in `+ui/runApp.m` after extraction.

## `apps/wearable/private/runECGPrintApp.m`

### Current Responsibility Map

| Responsibility | Current location | Target owner |
| --- | --- | --- |
| Public launch command | `apps/wearable/labkit_ECGPrint_app.m` | unchanged |
| Private app body | `apps/wearable/private/runECGPrintApp.m` | future `apps/wearable/ecg_print/labkit_ECGPrint_app.m` plus `+ecg_print` |
| Import option parsing | runner (`currentImportOptions`, `parseColumnSpec`, `parseColumnList`) | `ecg_print.io` |
| Import status text and header preview | runner local functions | `ecg_print.view` for status text; `ecg_print.io` for preview |
| Analysis table construction | runner (`analysisTable`, `movingMedian`) | `ecg_print.export` or `ecg_print.view` |
| Summary rows | runner (`buildSummaryRows`, `initialSummaryRows`) | `ecg_print.view` |
| Peak method label mapping | runner (`peakMethodValue`) | `ecg_print.ops` or `ecg_print.state` |
| Waveform/template/noise/SNR plotting | runner | keep runner initially; later extract plot-data preparation only |
| Alerts, file dialogs, callback ordering | runner | runner |

### Next Extraction Target

Create `apps/wearable/ecg_print/+ecg_print/+io` and
`apps/wearable/ecg_print/+ecg_print/+view` only when the first helper is
extracted. Start with import option normalization or summary rows because both
are GUI-free and directly testable.

Do not move `runECGPrintApp` into `+ui/runApp.m` as a first step.

### Direct Test Target

Add `tests/unit/apps/wearable` coverage that calls the new non-UI helper
directly. The first test should avoid real lab files and use synthetic option
values or synthetic recording structs.

### Exit Criteria

- The private runner no longer owns import option normalization, summary rows,
  or analysis/export table construction.
- The public launch command remains `labkit_ECGPrint_app`.
- The GUI path uses the extracted helpers.
- Only then should runner relocation begin.

## `apps/dic/private/runDICPreprocessApp.m`

### Current Responsibility Map

| Responsibility | Current location | Target owner |
| --- | --- | --- |
| Public launch command | `apps/dic/labkit_DICPreprocess_app.m` | unchanged |
| Private app body | `apps/dic/private/runDICPreprocessApp.m` | future DIC preprocess app-owned package |
| Registration and crop geometry helpers | existing `apps/dic/private/*.m` helpers | future `dic_preprocess.ops` where app-specific |
| Mask boundary and mask canvas transforms | existing private helpers plus runner state | future `dic_preprocess.ops` and `dic_preprocess.state` |
| Summary/detail text | runner (`refreshSummary`, `currentPairSizeText`) plus private summary helpers | `dic_preprocess.view` |
| Export filename/path defaults and image writes | runner plus private helpers | `dic_preprocess.export` or `dic_preprocess.io` |
| ROI drawing, anchor editor coordination, scroll zoom | runner plus `labkit.ui.tool` runtime | runner for coordination; app `+ui` only for control construction |
| Undo/history snapshots | runner | `dic_preprocess.state` only after shape is covered by tests |
| Alerts, user log wording, callback order | runner | runner |

### Next Extraction Target

Start with state/view helpers, not UI relocation. Good first candidates are
current-pair summary text, history snapshot construction, or mask canvas
normalization because they can be tested with synthetic image arrays and structs.

Do not move the whole private folder into a package. Classify each helper as
`+ops`, `+view`, `+export`, `+io`, `+state`, or runner-only before moving it.

### Direct Test Target

Add `tests/unit/apps/dic` coverage for the first non-UI helper before changing
the private runner call site. GUI structural DIC tests are not enough to prove
runner complexity was reduced.

### Exit Criteria

- `runDICPreprocessApp` no longer owns deterministic state/view/export helpers.
- Existing private helper inventory shrinks through app-owned package migration.
- The public launch command and DIC workflow behavior remain unchanged.
- Runner relocation happens only after directly tested helpers exist.
