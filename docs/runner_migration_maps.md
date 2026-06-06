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
| `apps/dic/private/runDICPreprocessApp.m` | DIC | Private runner coordinates image loading, registration, crop, mask editing, preview, state history, and exports. App-owned `dic_preprocess.view.buildSummary` now owns summary text construction. | Continue with small deterministic state/view/export helpers; do not relocate the whole runner. |

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

## `apps/dic/private/runDICPreprocessApp.m`

### Current Responsibility Map

| Responsibility | Current location | Target owner |
| --- | --- | --- |
| Public launch command | `apps/dic/labkit_DICPreprocess_app.m` | unchanged |
| Private app body | `apps/dic/private/runDICPreprocessApp.m` | future DIC preprocess app-owned package |
| Registration and crop geometry helpers | existing `apps/dic/private/*.m` helpers | future `dic_preprocess.ops` where app-specific |
| Mask boundary and mask canvas transforms | existing private helpers plus runner state | future `dic_preprocess.ops` and `dic_preprocess.state` |
| Summary text | `dic_preprocess.view.buildSummary` | already extracted |
| Detail text | runner callbacks plus private crop/transform summary helpers | future `dic_preprocess.view` where deterministic |
| Export filename/path defaults and image writes | runner plus private helpers | `dic_preprocess.export` or `dic_preprocess.io` |
| ROI drawing, anchor editor coordination, scroll zoom | runner plus `labkit.ui.tool` runtime | runner for coordination; app `+ui` only for control construction |
| Undo/history snapshots | runner | `dic_preprocess.state` only after shape is covered by tests |
| Alerts, user log wording, callback order | runner | runner |

### Next Extraction Target

Continue with state/view helpers, not UI relocation. Good next candidates are
history snapshot construction, mask canvas normalization, or detail text built
from crop/transform state because they can be tested with synthetic image arrays
and structs.

Do not move the whole private folder into a package. Classify each helper as
`+ops`, `+view`, `+export`, `+io`, `+state`, or runner-only before moving it.

### Direct Test Target

Direct DIC unit tests now cover `dic_preprocess.view.buildSummary`. Extend
`tests/unit/apps/dic` before changing each new non-UI runner call site. GUI
structural DIC tests are not enough to prove runner complexity was reduced.

### Exit Criteria

- `runDICPreprocessApp` no longer owns deterministic state/view/export helpers.
- Existing private helper inventory shrinks through app-owned package migration.
- The public launch command and DIC workflow behavior remain unchanged.
- Runner relocation happens only after directly tested helpers exist.
