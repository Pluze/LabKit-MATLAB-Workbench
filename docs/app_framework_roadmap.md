# App Framework Roadmap

This roadmap defines the next stable architecture direction for Gamry Electrochemistry Workbench.

The core design goal is a codebase with three reusable library surfaces plus independent apps:

```text
GUI library: scientific-app shells, panels, controls, logs, and reusable UI state helpers
Gamry/DTA library: DTA discovery, parsing, type detection, loading, item/session data APIs
utility library: small generic helpers shared by GUI and Gamry/DTA code
experiment-specific apps outside the reusable library
```

Future work should let a developer add a new experiment, a new GUI shell, or a new DTA format with minimal changes to the other parts. The modules should also remain reusable outside this repository when a downstream project only needs the GUI framework, only needs DTA loading/parsing, or only needs a small utility.

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

- public app entry points and app bodies now live under `apps/`
- app bodies and app-specific workflow helpers are now collapsed into public `apps/*.m` files
- the temporary `apps/+gamrywb_apps` migration namespace has been removed; do not recreate it unless there is a short-lived, test-driven migration reason
- common GUI shells and panels live under `+gamrywb/+ui`
- low-level pulse detection and broadly reusable math/data helpers may live under `+gamrywb/+analysis`; experiment-specific workflow calculations live with the owning app
- app-specific plotting helpers live with the owning app; reusable GUI/axes primitives live under `+gamrywb/+ui`
- parser/session/data helpers live under `+gamrywb/+dta`, `+gamrywb/+io`, and `+gamrywb/+data`
- cross-cutting string, struct, numeric, and CSV escaping helpers live under `+gamrywb/+util`

Main remaining bottleneck:

```text
future apps still need clearer reusable GUI/DTA API examples and more golden behavior references
```

Therefore, the next high-value step is improving reusable API examples and golden validation coverage while keeping tests focused on behavior and boundaries, not more GUI-helper extraction.

---

## 2. Library Layers And App Layer

The project should stabilize around three reusable library surfaces and one non-library app layer:

```text
Library 1: scientific-app GUI framework
Library 2: Gamry/DTA processing API
Library 3: utility base
App layer: app-specific scientific workflow
```

Each reusable library surface should be independently useful. MATLAB package folders can remain granular; the point is ownership clarity, not forcing everything into exactly three folders.

Layer independence targets:

```text
Scientific-app GUI framework:
  reusable controls, shells, layout, and state-display helpers
  no parser calls, scientific equations, export columns, or Gamry-only assumptions

Gamry/DTA processing API:
  DTA discovery, type detection, parser dispatch, item normalization, and status/reporting
  no figures, controls, callbacks, app plot choices, or experiment-specific calculations

Utility base:
  small string, struct, numeric, file-name, CSV-escaping, and parsing helpers with no GUI, parser-family, or experiment assumptions
  no scientific result definitions, plot labels, DTA table schemas, or app workflow state

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

## 4. Layer 2 — Gamry/DTA Processing API

This is the next priority.

The DTA layer should provide a clean, GUI-free way to discover, parse, normalize, and load DTA files.

It should eventually allow code like this:

```matlab
files = gamrywb.dta.findFiles(folder);
items = gamrywb.dta.loadFiles(files, "chrono");
results = myAnalysis(items, options);
T = myExportTable(results);
```

For scripts or prototypes that do not need session duplicate handling:

```matlab
items = gamrywb.dta.loadFolder(folder, "chrono");
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
  findFiles.m
  detectType.m
  loadFile.m
  loadFiles.m
  loadFolder.m
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
filepaths = gamrywb.dta.findFiles(folder);
kind = gamrywb.dta.detectType(filepath);
[item, status] = gamrywb.dta.loadFile(filepath, expectedKind);
[items, report] = gamrywb.dta.loadFiles(filepaths, expectedKind);
[items, report] = gamrywb.dta.loadFolder(folder, expectedKind);
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

## 5. Layer 3 — Utility Base

The utility base owns only small helpers that are useful across GUI, DTA, data, analysis, and app code without importing any of their domain assumptions.

It may provide:

- string and field-name sanitization
- CSV escaping
- struct append/merge helpers
- simple numeric index/window utilities
- positive scalar parsing
- data-like value checks

It must not know:

- DTA table names or parser family choices
- GUI handles, controls, or layout state
- CIC, CSC, VT, EIS, or chrono result definitions
- export column schemas
- scientific thresholds or units

Do not move code into `+gamrywb/+util` just because it is short. A utility helper is justified only when at least two layers need it and its name can be explained without project-specific vocabulary.

---

## 6. App-Specific Scientific Workflow

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
+gamrywb/+dta/findFiles.m
+gamrywb/+dta/loadFile.m
+gamrywb/+dta/loadFiles.m
+gamrywb/+dta/loadFolder.m
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

The EIS app implementation now lives directly in `apps/gamrywb_EIS_app.m`, not under `apps/private` or `+gamrywb/+app`, and uses `gamrywb.dta.findFiles(folder)` plus `gamrywb.dta.loadFile(filepath, "eis")` for DTA discovery/loading. This is the reference direction for future apps: a public app file with clear local sections that calls the DTA and GUI APIs.

EIS overlay axis selection, overlay plotting, and plot-export table construction now live as local functions in `apps/gamrywb_EIS_app.m`, not in reusable `+gamrywb/+analysis`, `+gamrywb/+plot`, `+gamrywb/+io`, or the transitional `apps/+gamrywb_apps` namespace.

The Chrono overlay app implementation now lives directly in `apps/gamrywb_ChronoOverlay_app.m`, not under `apps/private`, `apps/+gamrywb_apps`, or `+gamrywb/+app`, and uses `gamrywb.dta.findFiles(folder)` plus `gamrywb.dta.loadFile(filepath, "chrono")` for DTA discovery/loading. Pulse-gap alignment, VT/IT overlay plotting, and overlay export table construction are local functions in the app file, not reusable library APIs.

The CSC app implementation now lives directly in `apps/gamrywb_CSC_app.m`, not under `apps/private`, `+gamrywb/+app`, or `apps/+gamrywb_apps`, and uses `gamrywb.dta.loadFile(filepath, "cvct")` for file loading. CSC-specific charge calculations, CT/CV charge subcalculations, and sign-split integration are local functions in the public app file, not reusable `+gamrywb/+analysis` APIs or transitional app-helper package APIs. Generic selected-curve plotting lives in `gamrywb.ui.plotCurveXY`. Because the CSC app has no CSV export workflow, it does not keep standalone result-table/export helpers.

The CIC app implementation now lives directly in `apps/gamrywb_CIC_app.m`, not under `apps/private`, `apps/+gamrywb_apps`, or `+gamrywb/+app`, and uses `gamrywb.dta.findFiles(folder)` plus `gamrywb.dta.loadFile(filepath, "chrono")` for DTA discovery/loading. CIC-specific voltage-transient analysis, injected-charge calculation, water-window checks, result-table, CSV, and batch-table helpers are local functions in the public app file, not reusable `+gamrywb/+analysis`, `+gamrywb/+io`, or `+gamrywb/+ui` APIs.

The VT resistance app implementation now lives directly in `apps/gamrywb_VTResistance_app.m`, not under `apps/private`, `+gamrywb/+app`, or `apps/+gamrywb_apps`, and uses `gamrywb.dta.findFiles(folder)` plus `gamrywb.dta.loadFile(filepath, "chrono")` for DTA discovery/loading. VT-specific resistance analysis, steady-window and baseline subcalculations, result-table construction, batch-table display data, and CSV writing are local functions in the public app file, not reusable `+gamrywb/+analysis`, `+gamrywb/+io`, or `+gamrywb/+ui` APIs.

These are the reference paths for adopting the DTA facade and app-side workflow ownership in future apps.

Remaining migration candidates:

```text
App-side helper packages: removed as a migration layer; do not reintroduce them as a framework
Remaining +analysis functions: keep the package pulse-detection focused; classify any other helper before adding new behavior there
Generic GUI/session helpers now live in +gamrywb/+ui; do not recreate +gamrywb/+app for app-specific workflow code
```

Suggested commit:

```text
refactor: fold CSC helpers into app file
refactor: fold VT helpers into app file
refactor: fold CIC helpers into app file
test: streamline app boundary tests
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

Also avoid expanding `+gamrywb/+analysis` or app-specific export helpers with new experiment decisions. Those packages currently contain transitional behavior-preserving code, not the desired final home for experiment design.

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
