# App Framework Roadmap

This roadmap defines the next stable architecture direction for Gamry Electrochemistry Workbench.

The core design goal is a codebase with two reusable library parts plus independent apps:

```text
Gamry/DTA parsing-loading library
scientific-app base GUI library
experiment-specific apps outside the reusable library
```

If utilities are needed by both reusable libraries, keep them in a smaller shared utility base. Future work should let a developer add a new experiment, a new GUI shell, or a new DTA format with minimal changes to the other two parts. The modules should also remain reusable outside this repository when a downstream project only needs the GUI framework or only needs DTA loading/parsing.

Experiment-specific scientific workflow belongs with the app, not in the reusable library. This includes formulas, analysis options, result schemas, plot choices, annotations, summaries, and export formats. The long-term ideal is one experiment app `.m` file that calls the DTA and GUI libraries and contains its own scientific workflow. Keep only genuinely broad, parameter-light math/data utilities in `+gamrywb`.

The previous refactor successfully moved the project from legacy GUI scripts to package-backed apps with reusable GUI helpers. The project is now already reasonably convenient for building apps that resemble the existing Chrono, EIS, VT, CIC, and CSC tools.

The next goal is not to keep extracting small GUI helpers. The next goal is to make new app creation predictable:

```text
new app = GUI framework + DTA processing API + app-specific scientific workflow
```

A future developer should be able to:

- reuse the GUI framework without using Gamry-specific scientific analysis
- reuse the DTA loading/parsing/normalization system without launching a GUI
- create a new scientific app by defining file requirements, analysis options, plot behavior, result fields, and export format
- keep each experiment's scientific workflow local to that app
- prefer one app `.m` file per experiment instead of creating an app framework or app-science library
- add support for a new DTA family without rewriting existing app GUIs
- redesign or add a GUI shell without changing parser behavior or scientific formulas
- avoid copying large existing app files
- avoid adding one-off helpers for every small UI pattern

Every roadmap item should be judged by this rule:

```text
Does this make GUI, DTA loading, and experiment logic more independently reusable without hiding domain logic or adding abstraction burden?
```

---

## 1. Current App-Building Convenience

Current status:

```text
building an app similar to existing tools: good
building a completely new DTA-driven app: possible with a first DTA facade, still app-glue-heavy
reusing the GUI framework alone: mostly possible
reusing the DTA system alone: minimally supported for supported fixture families
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
- app bodies should live under `apps/private`; EIS, Chrono overlay, CSC, VT resistance, and CIC are the first reference migrations
- common GUI shells and panels live under `+gamrywb/+ui`
- broad scientific calculations live under `+gamrywb/+analysis`; experiment-specific workflow calculations live with the owning app
- plotting helpers live under `+gamrywb/+plot`
- parser/export/session helpers live under `+gamrywb/+io` and `+gamrywb/+data`

Main remaining bottleneck:

```text
existing app bodies still need to move out of the reusable `+gamrywb` package and adopt the DTA facade before parser/item details are consistently hidden
```

Therefore, the next high-value step is adopting the DTA-facing API in one existing app, not more GUI-helper extraction.

---

## 2. Three-Layer Architecture

The project should stabilize around two reusable libraries and one non-library app layer:

```text
Library 1: scientific-app GUI framework
Library 2: Gamry/DTA processing API
App layer: app-specific scientific workflow
```

Each reusable library should be independently useful.

Layer independence targets:

```text
Scientific-app GUI framework:
  reusable controls, shells, layout, and state-display helpers
  no parser calls, scientific equations, export columns, or Gamry-only assumptions

Gamry/DTA processing API:
  DTA discovery, type detection, parser dispatch, item normalization, and status/reporting
  no figures, controls, callbacks, app plot choices, or experiment-specific calculations

Experiment app design:
  accepted DTA family, analysis options, calculations, plots, result summaries, and export format
  lives outside the reusable +gamrywb library, may compose GUI and DTA helpers, and keeps scientific decisions visible in the app layer
```

The architecture should remain MATLAB-friendly. Prefer plain functions and structs until a repeated, proven need justifies a heavier abstraction.

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
- parser-family extension points when a new DTA format is added
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

### Current package

The first DTA facade lives in:

```text
+gamrywb/+dta/
  detectType.m
  loadFile.m
  loadFiles.m
```

This package should be a facade over existing lower-level code.

Do not rewrite parsers just to create this package.

Initial implementation should delegate to existing functions in:

```text
+gamrywb/+io
+gamrywb/+data
```

### Minimal first version

The minimal first version is:

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

Batch `items` are a cell array so `"auto"` loads can mix supported DTA schemas without forcing an opaque common superclass or padded struct.

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

The app layer also owns experiment-specific scientific calculations. Do not move those calculations into `+gamrywb/+analysis` or an app framework just because two apps have similarly shaped callbacks. Extract only low-level math utilities when they are truly independent of experiment parameters, result definitions, labels, export columns, and validation assumptions.

A new app should be describable with three contracts.

The app layer is intentionally not a generic engine yet. Experiment logic should stay readable and close to the app that owns it. If an abstraction makes it harder to see the scientific assumptions, keep that code explicit.

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

Status: complete for the conservative first version.

Added:

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

Do not expand this into a schema framework until an app migration proves the missing contract.

### Phase C: Move app implementations out of `+gamrywb` while using the DTA facade

Status: started with EIS, Chrono overlay, CSC, VT resistance, and CIC as reference app-structure migrations. EIS, Chrono overlay, CSC, VT resistance, and CIC now use the DTA facade for file loading.

Recommended candidates:

```text
EIS app: simpler plotting/export flow
VT resistance app: representative chrono single-file analysis flow
CIC app: representative chrono single-file analysis/export flow
```

Goal:

- EIS app behavior unchanged
- EIS app no longer manually knows EIS item-construction details
- DTA loading can also be used independently in scripts
- tests prove no behavior change
- the migrated app demonstrates the intended split between GUI shell, DTA loading, and experiment-specific analysis/export

The EIS app implementation now lives under `apps/private`, not under `+gamrywb/+app`, and uses `gamrywb.dta.loadFile(filepath, "eis")` for file loading.

The Chrono overlay app implementation now lives under `apps/private`, not under `+gamrywb/+app`, and uses `gamrywb.dta.loadFile(filepath, "chrono")` for file loading. Pulse-gap alignment, VT/IT overlay plotting, and overlay export table construction now live under `apps/+gamrywb_apps/+chrono`, not in reusable `+gamrywb/+analysis`, `+gamrywb/+plot`, or `+gamrywb/+io`.

The CSC app implementation now lives under `apps/private`, not under `+gamrywb/+app`, and uses `gamrywb.dta.loadFile(filepath, "cvct")` for file loading. CSC-specific charge and result-table calculations live under `apps/+gamrywb_apps/+csc`, not in reusable `+gamrywb/+analysis` or `+gamrywb/+io`. This app-side package is a migration step for testability, not a new reusable app abstraction; collapse it into the CSC app file if/when tests can still verify behavior cleanly.

The CIC app implementation now lives under `apps/private`, not under `+gamrywb/+app`, and uses `gamrywb.dta.loadFile(filepath, "chrono")` for file loading. CIC-specific voltage-transient analysis, result-table, CSV, and batch-table helpers live under `apps/+gamrywb_apps/+cic`, not in reusable `+gamrywb/+analysis`, `+gamrywb/+io`, or `+gamrywb/+ui`.

The VT resistance and CIC app implementations now live under `apps/private`, not under `+gamrywb/+app`, and use `gamrywb.dta.loadFile(filepath, "chrono")` for file loading. VT-specific resistance helpers and CIC-specific voltage-transient/export/table helpers live under `apps/+gamrywb_apps`, not in reusable `+gamrywb/+analysis`, `+gamrywb/+io`, or `+gamrywb/+ui`.

These are the reference paths for adopting the DTA facade and app-side workflow ownership in the remaining apps.

Remaining migration candidates:

```text
App-side helper packages: keep only as temporary testable waypoints; do not grow them into a framework
Remaining +analysis functions: classify broad chrono primitives versus experiment-specific calculations before moving anything else
Generic GUI/session helpers now live in +gamrywb/+ui; do not recreate +gamrywb/+app for app-specific workflow code
```

Suggested commit:

```text
refactor: use dta facade in EIS app
refactor: use dta facade in chrono overlay app
refactor: move EIS app implementation out of gamrywb package
refactor: move chrono overlay app implementation out of gamrywb package
refactor: move CSC app workflow out of gamrywb package
refactor: move VT resistance workflow out of gamrywb package
```

### Phase D: Define lightweight extension contracts

Do not implement a heavy generic app engine yet.

Start with documentation or a small example file. The goal is to make extension boundaries clear, not to create a schema framework.

A future experiment app should be defined by:

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

A future DTA family should be defined by:

```matlab
dtaSpec = struct();
dtaSpec.kind = "new_kind";
dtaSpec.detector = @myDetector;
dtaSpec.loader = @myLoader;
dtaSpec.requiredFields = ["T", "Vf", "Im"];
dtaSpec.fixture = "demo/new_kind_reference.DTA";
```

A future GUI shell should be defined by:

```matlab
guiSpec = struct();
guiSpec.shell = "twoPane";
guiSpec.fileMode = "multi";
guiSpec.plotLayout = "singleAxes";
guiSpec.resultSurface = "table";
```

Keep these as contracts first. Add runtime machinery only after real app migrations show repeated structure that is clearer as code than as explicit app logic.

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

Also avoid expanding `+gamrywb/+analysis`, `+gamrywb/+plot`, or app-specific export helpers with new experiment decisions. Those packages currently contain transitional behavior-preserving code, not the desired final home for experiment design.

Do not make the app body read like an opaque list of helper calls.

The project should stay MATLAB-friendly, easy to inspect, and easy to debug.

Also avoid coupling reversals:

```text
GUI helpers calling DTA parsers
DTA helpers importing app-specific analysis
experiment apps duplicating low-level parser dispatch
new format support changing GUI layout code
new GUI shells changing scientific/export contracts
```

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
