# App Framework Roadmap

This roadmap replaces the previous extraction log.

The previous roadmap tracked many small helper extractions. That stage is now mature enough. The next goal is not to keep extracting every repeated UI block. The next goal is to stabilize the project around a clean, reusable three-layer architecture.

Target outcome:

```text
new app = GUI framework + DTA processing system + app-specific scientific requirements
```

A future developer should be able to:

- reuse the GUI framework without using Gamry-specific analysis code
- reuse the DTA parsing/processing system without launching a GUI
- add a new scientific app by defining its data requirements, analysis function, plots, controls, and export behavior
- avoid copying large app files
- avoid adding one-off helpers for every small UI pattern

---

## 1. Design Principle

The project should be organized around three layers:

```text
Layer 1: GUI framework
Layer 2: DTA processing system
Layer 3: App-specific scientific workflow
```

Each layer should be independently useful.

### 1.1 GUI framework

The GUI framework owns reusable interface structure only.

It may provide:

- app shells
- panels
- buttons
- listboxes
- log areas
- result tables
- axes panels
- dropdown rows
- generic callback wiring surfaces
- layout helpers

It must not know:

- CIC
- CSC
- VT resistance
- EIS equations
- pulse timing science
- electrode area conventions
- water-window safety rules
- export column semantics

A GUI helper is acceptable only if it can be explained without scientific domain words.

Good examples:

```text
createTwoPaneShell
createTabbedDualPlotShell
createResultTablePanel
createLogPanel
createTopBottomPlotControls
appendLog
```

Bad examples:

```text
createCICSafetyPanel
createResistanceSummaryPanel
createElectrodeAreaControl
createWaterWindowTable
```

Those belong in app-specific code.

### 1.2 DTA processing system

The DTA layer owns file discovery, parsing, normalization, item construction, session storage, and export-table construction.

It should be reusable without GUI.

It may provide:

- recursive DTA discovery
- DTA type detection
- parser dispatch
- normalized parsed structs
- item factories
- session add/remove helpers
- result table builders
- CSV writers
- validation fixtures

It must not know:

- uifigure
- uigridlayout
- uialert
- listbox state
- dropdown state
- button callbacks

The DTA system should eventually make this possible:

```matlab
files = gamrywb.io.findDTAFilesRecursive(folder);
items = gamrywb.dta.loadFiles(files, "chrono");
results = myAnalysis(items, options);
T = myExportTable(results);
```

No GUI should be required for that flow.

### 1.3 App-specific scientific workflow

The app layer connects a scientific use case to the GUI framework and the DTA processing system.

It owns:

- app title
- supported DTA type
- analysis options
- domain-specific labels
- domain-specific result fields
- plot choices
- plot annotations
- export column names
- result summary text
- scientific validation assumptions

The app layer may call GUI and DTA helpers, but GUI and DTA helpers should not call app-specific science.

---

## 2. Current State

The project has already completed major structural work:

- public entry points are thin files under `apps/`
- app bodies live under `+gamrywb/+app`
- scientific analysis lives under `+gamrywb/+analysis`
- file parsing and export helpers live under `+gamrywb/+io`
- item/session helpers live under `+gamrywb/+data`
- plotting helpers live under `+gamrywb/+plot`
- common GUI pieces live under `+gamrywb/+ui`

The app framework extraction has already gone far enough that further abstraction should be treated carefully.

Current risk:

```text
helper proliferation can make the code harder to read even if repeated lines decrease
```

Therefore, future work must prioritize stable boundaries, reusable contracts, and simple app authoring over further mechanical extraction.

---

## 3. Stop Rules Against Over-Abstraction

Do not add a new helper unless all of these are true:

1. The same pattern appears in at least two real apps.
2. The helper name can be domain-neutral.
3. The helper does not contain scientific labels, formulas, units, or export columns.
4. The helper reduces conceptual duplication, not just line count.
5. The calling app remains easier to read after the extraction.
6. A layout or helper test can lock the expected behavior.

Do not extract:

- one-off controls
- app-specific summaries
- app-specific result fields
- app-specific export columns
- scientific callback order unless it is truly shared
- anything that makes the app body read like a list of opaque helper calls

When unsure, leave the code in the app layer.

---

## 4. Desired Final Architecture

Preferred long-term shape:

```text
apps/
  gamrywb_CIC_app.m
  gamrywb_VTResistance_app.m
  gamrywb_CSC_app.m
  gamrywb_EIS_app.m
  gamrywb_ChronoOverlay_app.m

+gamrywb/+app/
  launchCICApp.m
  launchVTResistanceApp.m
  launchCSCApp.m
  launchEISApp.m
  launchChronoOverlayApp.m
  shared app orchestration helpers

+gamrywb/+ui/
  reusable GUI shells, panels, controls, and UI state helpers

+gamrywb/+dta/
  DTA type detection, parser dispatch, file loading, and normalized item construction

+gamrywb/+io/
  low-level parsers, CSV writers, session save/load, export table utilities

+gamrywb/+data/
  normalized item/session structures and access helpers

+gamrywb/+analysis/
  scientific computations independent of GUI

+gamrywb/+plot/
  plotting functions that draw into supplied axes
```

`+gamrywb/+dta` does not need to appear immediately, but the design should move toward a clear DTA-facing API instead of making every app manually know parser details.

---

## 5. Three-Layer App Contract

A new app should be describable with three separate blocks.

### 5.1 GUI contract

The app declares what interface structure it needs:

```text
shell type
file selection mode
option controls
summary panel
result table
plot layout
log behavior
```

Example:

```text
shell: tabbed dual plot
file mode: single selected file from loaded session
plots: top/bottom axes with X/Y dropdowns
summary: read-only rows
results: batch result table
```

### 5.2 DTA contract

The app declares what file types and parsed fields it needs:

```text
accepted DTA family
required parsed columns
required metadata
item factory
session kind
batch behavior
```

Example:

```text
DTA family: MULTI_STEP_CHRONOPOT
required arrays: T, Vf, Im
required metadata: optional ISTEP/TSTEP pulse timing
item factory: chrono item
session kind: cic_vt
```

### 5.3 Scientific contract

The app declares its own science:

```text
options
analysis function
result struct
plot annotations
summary fields
export columns
validation fixtures
```

Example:

```text
analysis: computeCIC
options: water window, sample delay, area override, pulse detection mode
plots: VT/IT with markers and pulse shading
export: File, Amp, Emc, Ema, Qc, Qa, Qtot, Safe
```

This separation should make it possible to build a new app by writing a small app-specific layer rather than copying an old GUI.

---

## 6. Recommended Next Phase

### Phase A: Stabilize and audit current framework

Do this before adding more helpers.

Tasks:

- run the default MATLAB test suite
- run the GUI test suite if available
- review the current `+gamrywb/+ui` helper list
- remove or merge helpers that are too narrow or confusing
- confirm that GUI helpers contain no scientific domain semantics
- confirm that app bodies are still readable
- update tests if GUI contracts changed intentionally

Deliverable:

```text
short audit update in this file or CHANGELOG only if something meaningful changes
```

Do not add a new roadmap file.

### Phase B: Define the DTA-facing API

The DTA system should become easier to call independently of any app.

Candidate future package:

```text
+gamrywb/+dta/
  detectType.m
  loadFile.m
  loadFiles.m
  makeItem.m
  validateItem.m
```

Possible usage:

```matlab
item = gamrywb.dta.loadFile(filepath);
items = gamrywb.dta.loadFiles(filepaths, "chrono");
```

Rules:

- keep low-level parser code in `+io` unless moving it clearly improves the API
- keep GUI dialogs out of `+dta`
- return status/error information instead of showing alerts
- preserve existing parser behavior
- preserve existing item fields until tests prove a safe migration path

### Phase C: Define a minimal app-definition template

Do not build a heavy generic app engine yet.

First define a lightweight template for future apps:

```matlab
spec = struct();
spec.name = "New App Name";
spec.sessionKind = "new_session_kind";
spec.fileMode = "single";      % or "multi"
spec.shell = "tabbedDualPlot"; % or "twoPane"
spec.loader = @myLoader;
spec.analyzer = @myAnalyzer;
spec.plotter = @myPlotter;
spec.exporter = @myExporter;
```

This template is documentation first. Only implement a generic runner if at least two future apps can use it cleanly.

### Phase D: Make one new or existing app follow the template

Pick one app as the reference implementation.

Recommended candidate:

```text
EIS app if testing simple GUI/DTA/plot integration
VT resistance app if testing chrono single-file analysis integration
```

Goal:

- app-specific science remains visible
- framework handles only generic GUI and session behavior
- DTA loading is callable outside GUI
- tests prove behavior did not change

### Phase E: Create a new-app checklist

Add a short checklist for future app creation.

A future app should define:

```text
1. DTA family and parser requirements
2. item/session kind
3. scientific options
4. analysis result struct
5. plots and axes labels
6. summary fields
7. result table columns
8. export format
9. validation fixture
10. GUI shell type
```

If these ten items are clear, the GUI framework and DTA system should provide most of the remaining scaffolding.

---

## 7. What Not To Do Next

Do not continue blindly extracting helpers.

Avoid adding helpers such as:

```text
createCICPanel
createVTResistancePanel
createWaterWindowControls
createPulseDetectionSummary
createElectrodeAreaOptions
```

Avoid introducing:

```text
large class hierarchies
generic app engines
schema frameworks
plugin systems
reflection-heavy dispatch
opaque callback registries
```

The project should stay MATLAB-friendly, easy to inspect, and easy to debug.

---

## 8. Testing Requirements

Every framework-level change should preserve both scientific and GUI behavior.

Run:

```bash
scripts/run_matlab_tests.sh
```

When GUI construction changes, also run:

```bash
scripts/run_matlab_tests.sh --gui
```

Test priorities:

- parser outputs remain stable
- analysis outputs remain stable
- export columns remain stable
- app entry points still launch
- GUI control labels remain stable
- helper tests cover reusable UI behavior
- DTA layer can be called without GUI

Do not claim tests passed unless they actually ran.

---

## 9. Success Criteria

This roadmap succeeds when:

- the GUI framework can be reused without scientific code
- the DTA processing system can be reused without GUI
- a new app can be created by defining app-specific requirements rather than copying an existing app
- app scientific logic remains readable and visible
- UI helpers remain domain-neutral
- DTA helpers remain GUI-free
- app code remains easier to read after refactoring
- no scientific outputs or export formats change unintentionally

The goal is not the smallest possible number of lines.

The goal is a maintainable workbench where GUI scaffolding, DTA processing, and scientific app logic are cleanly separated.
