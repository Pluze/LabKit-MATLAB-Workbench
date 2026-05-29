# New App Playbook

Use this playbook when adding a new experiment app. It turns the architecture roadmap into a practical checklist while keeping the codebase MATLAB-friendly and explicit.

The target shape is:

```text
apps/gamrywb_NewExperiment_app.m
  owns experiment-specific analysis, plotting, summaries, exports, labels, and test hooks
  calls +gamrywb/+dta for GUI-free file discovery/loading
  calls +gamrywb/+data for item/session/table access
  calls +gamrywb/+ui for domain-neutral GUI structure
  calls +gamrywb/+util only for genuinely generic helpers
```

Do not create a new app framework, app-specific helper package, class hierarchy, or schema engine just to start a new app. Write the first version as one public app file with clear local sections.

## Before Coding

Write these three contracts near the design notes, issue, or PR description before adding controls.

### GUI Contract

Define:

```text
app title
shell helper: createTwoPaneShell or createTabbedDualPlotShell
file mode: single-select or multi-select
controls and defaults
summary surface
result table columns shown in the GUI
plot layout and axes labels
log behavior
manual workflows that still need GUI checks
```

GUI labels are app decisions. Pass them into `+gamrywb/+ui` helpers; do not hardcode experiment words in reusable GUI helpers.

### DTA Contract

Define:

```text
accepted DTA kind: chrono, eis, cvct, or a new planned kind
required parsed columns
required metadata
item/session kind
single-file, batch, or folder behavior
normal load failure behavior
validation fixture or synthetic input
```

Apps should normally load through:

```matlab
[item, status] = gamrywb.dta.loadFile(filepath, "chrono");
```

Use direct parser calls only for parser development or parser-level tests.

### Scientific Contract

Define:

```text
options and defaults
analysis function inputs
result struct fields
failure messages
plot choices and annotations
summary fields
CSV/export column names and failed-row behavior
numeric tolerances and fixtures
```

Keep these choices local to the app. They are not reusable library APIs unless at least two real apps prove the same lower-level helper is clearer without hiding scientific assumptions.

## Recommended File Shape

Organize the public app file in this order:

```text
1. entrypoint, argument checks, optional narrow test hooks
2. app state initialization
3. GUI shell and controls
4. file open/folder callbacks
5. GUI-free loadOne/loadFiles session bridge
6. selection, clear, remove, refresh callbacks
7. app-specific analysis
8. app-specific plotting and annotations
9. app-specific summary/table/export code
10. small local formatting helpers
```

This structure is preferred over moving app-specific sections into `apps/private`, `apps/+gamrywb_apps`, or `+gamrywb/+app`.

## API Choices

Use the smallest reusable API that matches the workflow:

```text
explicit file load:       gamrywb.dta.loadFile
folder/script load:       gamrywb.dta.loadFolder
mixed batch load:         gamrywb.dta.loadFiles
GUI session add/remove:   gamrywb.data.addFilesToSession and removeSelectedItemsFromSession
table column access:      gamrywb.data.getColumn and getCurveXY
generic GUI shell:        gamrywb.ui.createTwoPaneShell or createTabbedDualPlotShell
generic plot primitive:   gamrywb.ui.plotXY with app/data-prepared X/Y vectors
small numeric/string ops: gamrywb.util.*
```

Avoid using lower-level `gamrywb.io.parse*` functions from app code unless the app is specifically validating or developing parser behavior.

## Extraction Rules

Keep code local when it contains:

```text
experiment names
scientific formulas
thresholds
units chosen for a result
plot labels or annotation semantics
CSV columns or failed-row formatting
callback choreography that is only similar by shape
```

Extract to `+gamrywb/+ui` only when the helper is domain-neutral and makes at least two real apps easier to read.

Extract to `+gamrywb/+dta`, `+gamrywb/+io`, or `+gamrywb/+data` only when the behavior is GUI-free and belongs to discovery, parsing, loading, item construction, table access, or session orchestration.

Extract to `+gamrywb/+util` only when the helper is small, cross-cutting, and explainable without project or experiment vocabulary.

## Testing Plan

For a new app, add focused tests for:

```text
DTA facade or parser behavior for the accepted fixture
analysis result fields and key numeric values
plot/export column naming or table shape
failed-row and failed-analysis behavior
app boundary checks in tests/test_architecture_boundaries.m
GUI smoke/layout checks only when entrypoint, layout, or callback wiring changes
```

Use narrow app test hooks for local app analysis/export functions when needed. Do not move one-app analysis or export code into reusable packages just to test it.

Run:

```bash
scripts/run_matlab_tests.sh
```

Run `scripts/run_matlab_tests.sh --gui` when GUI entrypoints, layout construction, callback wiring, or GUI helper behavior changes.
