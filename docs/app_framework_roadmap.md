# App Framework Roadmap

This roadmap defines the next stable architecture direction for Gamry Electrochemistry Workbench.

The previous refactor successfully moved the project from legacy GUI scripts to package-backed apps with reusable GUI helpers. The project is now already reasonably convenient for building apps that resemble the existing Chrono, EIS, VT, CIC, and CSC tools.

The next goal is not to keep extracting small GUI helpers. The next goal is to make new app creation predictable:

```text
new app = GUI framework + DTA processing API + app-specific scientific workflow
```

A future developer should be able to:

- reuse the GUI framework without using Gamry-specific scientific analysis
- reuse the DTA loading/parsing/normalization system without launching a GUI
- create a new scientific app by defining file requirements, analysis options, plot behavior, result fields, and export format
- avoid copying large existing app files
- avoid adding one-off helpers for every small UI pattern

---

## 1. Current App-Building Convenience

Current status:

```text
building an app similar to existing tools: good
building a completely new DTA-driven app: possible but still glue-heavy
reusing the GUI framework alone: mostly possible
reusing the DTA system alone: not yet convenient enough
```

Practical assessment:

```text
similar Chrono/EIS/VT/CIC-style app: about 8/10 convenient
GUI framework reuse: about 7.5/10 convenient
DTA processing reuse: about 6/10 convenient
completely new app type: about 6/10 convenient
```

Why similar apps are now easier:

- public app entry points are thin wrappers under `apps/`
- app bodies live under `+gamrywb/+app`
- common GUI shells and panels live under `+gamrywb/+ui`
- scientific calculations live under `+gamrywb/+analysis`
- plotting helpers live under `+gamrywb/+plot`
- parser/export/session helpers live under `+gamrywb/+io` and `+gamrywb/+data`

Main remaining bottleneck:

```text
new apps still need to know too much about low-level parser and item-construction details
```

Therefore, the next high-value step is a DTA-facing API, not more GUI-helper extraction.

---

## 2. Three-Layer Architecture

The project should stabilize around three reusable layers:

```text
Layer 1: GUI framework
Layer 2: DTA processing API
Layer 3: App-specific scientific workflow
```

Each layer should be independently useful.

---

## 3. Layer 1 — GUI Framework

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
- layout helpers
- small generic UI state helpers

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

### Current GUI framework guidance

The current GUI helper layer is mature enough for now.

Do not keep extracting helpers just because code repeats.

Add a new GUI helper only if all are true:

1. the same pattern appears in at least two real apps
2. the helper name is domain-neutral
3. the helper contains no scientific labels, formulas, units, or export columns
4. the helper reduces conceptual duplication, not just line count
5. the app remains easier to read after the extraction
6. a layout/helper test can lock expected behavior

When unsure, leave code in the app layer.

---

## 4. Layer 2 — DTA Processing API

This is the next priority.

The DTA layer should provide a clean, GUI-free way to discover, parse, normalize, and load DTA files.

It should eventually allow code like this:

```matlab
files = gamrywb.io.findDTAFilesRecursive(folder);
items = gamrywb.dta.loadFiles(files, "chrono");
results = myAnalysis(items, options);
T = myExportTable(results);
```

or:

```matlab
item = gamrywb.dta.loadFile(filepath);
kind = gamrywb.dta.detectType(filepath);
```

The DTA layer may provide:

- DTA type detection
- parser dispatch
- recursive file loading wrappers
- normalized item construction
- status/error reporting
- batch loading without GUI dialogs
- validation of required arrays/metadata

It must not know:

- uifigure
- uigridlayout
- uialert
- listbox state
- dropdown state
- button callbacks
- app plot controls

### Candidate package

Add a future package:

```text
+gamrywb/+dta/
  detectType.m
  loadFile.m
  loadFiles.m
  makeItem.m
  validateItem.m
```

This package should be a facade over existing lower-level code.

Do not rewrite parsers just to create this package.

Initial implementation should delegate to existing functions in:

```text
+gamrywb/+io
+gamrywb/+data
```

### Minimal first version

A useful first version could be:

```matlab
[item, status] = gamrywb.dta.loadFile(filepath, expectedKind);
[items, report] = gamrywb.dta.loadFiles(filepaths, expectedKind);
kind = gamrywb.dta.detectType(filepath);
```

Where:

```text
expectedKind: "chrono", "eis", "cvct", or "auto"
status.ok: true/false
status.message: readable error or warning
status.kind: detected/loaded type
```

Rules:

- preserve current parser behavior
- preserve current item fields
- do not show GUI alerts from this layer
- return status information instead of throwing for normal file-mismatch cases
- throw only for programmer errors
- keep tests fixture-driven

---

## 5. Layer 3 — App-Specific Scientific Workflow

The app layer connects a scientific use case to the GUI framework and DTA processing API.

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

A new app should be describable with three contracts.

### 5.1 GUI contract

The app declares interface structure:

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

The app declares file and parsed-data requirements:

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

The app declares its science:

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

---

## 6. Recommended Next Phase

### Phase A: Freeze GUI helper growth

Do this before adding more UI helpers.

Tasks:

- run the default MATLAB test suite
- run the GUI test suite if available
- review current `+gamrywb/+ui` helper names
- confirm helpers are domain-neutral
- confirm app bodies remain readable
- remove or merge helpers only if they are clearly confusing

Do not add more GUI helpers unless justified by the stop rules above.

### Phase B: Build the minimal DTA facade

This is the main next development task.

Add:

```text
+gamrywb/+dta/detectType.m
+gamrywb/+dta/loadFile.m
+gamrywb/+dta/loadFiles.m
```

Keep it conservative:

- wrap existing parser/item functions
- do not rewrite parser internals
- do not change item fields
- return status/report structs
- keep it usable from scripts without GUI

Suggested first commit:

```text
feat: add gui-free dta loading facade
```

### Phase C: Use the DTA facade in one existing app

Pick one app as a reference migration.

Recommended candidates:

```text
EIS app: simpler plotting/export flow
VT resistance app: representative chrono single-file analysis flow
```

Goal:

- app behavior unchanged
- app no longer manually knows as much parser/item construction detail
- DTA loading can also be used independently in scripts
- tests prove no behavior change

Suggested commit:

```text
refactor: use dta facade in EIS app
```

or:

```text
refactor: use dta facade in VT resistance app
```

### Phase D: Define a lightweight new-app template

Do not implement a heavy generic app engine yet.

Start with documentation or a small example file.

A future app should be defined by:

```matlab
spec = struct();
spec.name = "New App Name";
spec.sessionKind = "new_session_kind";
spec.fileMode = "single";      % or "multi"
spec.shell = "tabbedDualPlot"; % or "twoPane"
spec.dtaKind = "chrono";
spec.analyzer = @myAnalyzer;
spec.plotter = @myPlotter;
spec.exporter = @myExporter;
```

This template is documentation first.

Only implement a generic runner if two future apps can use it cleanly without hiding scientific logic.

### Phase E: New-app checklist

A future app should define these ten items before coding:

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

If these are clear, the GUI framework and DTA facade should provide most remaining scaffolding.

---

## 7. What Not To Do Next

Do not continue blindly extracting GUI helpers.

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

Do not make the app body read like an opaque list of helper calls.

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

For the DTA facade, add tests that prove it can be used without GUI.

Test priorities:

- parser outputs remain stable
- analysis outputs remain stable
- export columns remain stable
- app entry points still launch
- GUI control labels remain stable
- helper tests cover reusable UI behavior
- DTA facade can be called without GUI
- DTA facade returns useful status/report structs

Do not claim tests passed unless they actually ran.

---

## 9. Success Criteria

This roadmap succeeds when:

- similar new apps can be built quickly without copying old app files
- the GUI framework can be reused without scientific code
- the DTA processing API can be reused without GUI
- a new app can be created by defining app-specific requirements rather than rewriting scaffolding
- app scientific logic remains readable and visible
- UI helpers remain domain-neutral
- DTA helpers remain GUI-free
- app code remains easier to read after refactoring
- no scientific outputs or export formats change unintentionally

The goal is not the smallest possible number of lines.

The goal is a maintainable workbench where GUI scaffolding, DTA processing, and scientific app logic are cleanly separated.
