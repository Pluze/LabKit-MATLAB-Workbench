# App Framework Roadmap

This roadmap describes the next refactor stage for Gamry Electrochemistry Workbench.

The v1.0 package-backed refactor moved runtime entry points into `apps/` and removed the old `legacy/` runtime layer. The current apps now call `+gamrywb` parser, data, analysis, plotting, export, session, and UI helpers directly. The next design problem is not legacy replacement. The next design problem is that the GUI apps still repeat a lot of layout, session, file-loading, logging, table, and plot scaffolding.

Goal:

```text
make future apps easier to build by extracting reusable GUI/application components
without changing scientific behavior or exported results
```

Non-goal:

```text
do not build a unified workbench GUI yet
```

---

## 1. Current Code Design Assessment

### 1.1 What is good now

The current architecture is much healthier than the original single-file GUI state.

Good patterns already present:

- App entry points live in `apps/`.
- Core scientific logic lives in `+gamrywb/+analysis`.
- File parsing and export helpers live in `+gamrywb/+io`.
- Item/session helpers live in `+gamrywb/+data`.
- Plot helpers live in `+gamrywb/+plot`.
- Some UI display helpers live in `+gamrywb/+ui`.
- Tests cover pure functions and noninteractive GUI layout contracts.
- App entry points generally reject unsupported inputs and optionally return the figure handle.
- Runtime no longer depends on the old `legacy/` directory.

This means the project has moved from:

```text
monolithic GUI scripts
```

to:

```text
package-backed apps with repeated GUI scaffolding
```

That is the right intermediate state.

### 1.2 Current design pattern

The current apps mostly follow this implicit pattern:

```text
app entry point
  -> initialize S state struct
  -> create uifigure
  -> create left controls
  -> create right plot area
  -> define nested callbacks
  -> callbacks call +gamrywb package helpers
  -> update UI widgets directly
```

This pattern is acceptable for v1.0, but it is becoming repetitive.

Common repeated elements include:

- input/output argument checks
- `S = struct()` state initialization
- `gamrywb.data.makeSession(...)`
- `uifigure` creation
- main `uigridlayout` with left controls and right plots
- optional draggable separator between left and right panels
- file-open and folder-open buttons
- file listbox handling
- duplicate file skipping
- `gamrywb.data.addFilesToSession(...)`
- clear-all behavior
- log text area and timestamped log append
- result table setup
- top/bottom plot controls
- axes initialization
- reset/swap/refresh plot buttons
- safe callbacks that work with empty sessions

These are application-framework concerns, not scientific analysis concerns.

### 1.3 Current weakness

The main weakness is that each app owns too much UI infrastructure directly.

Examples of current duplication:

- `gamrywb_CIC_app` and `gamrywb_VTResistance_app` both use a three-column layout with left tabs, a separator, a right dual-plot panel, file controls, result table, log tab, and top/bottom plot controls.
- `gamrywb_ChronoOverlay_app` and `gamrywb_EIS_app` both use a simpler two-pane layout with a left file/options/log area and a right plot area.
- `gamrywb_CSC_app`, `gamrywb_CIC_app`, and `gamrywb_VTResistance_app` all contain similar top/bottom axes controls.
- File loading, folder scanning, duplicate skipping, clearing, file-list refresh, and log append logic are repeated across apps.
- GUI layout contract tests assert the resulting surface, but the construction code itself is still app-local and verbose.

This makes future app development slower because every new app must copy and modify a large layout scaffold.

---

## 2. Design Direction

The next stage should introduce a small app framework layer.

The framework should be lightweight, functional, and MATLAB-struct based.

Do not introduce MATLAB classes yet.

Preferred dependency direction:

```text
apps/
  -> +gamrywb/+app
      -> +gamrywb/+ui
      -> +gamrywb/+data
      -> +gamrywb/+io
      -> +gamrywb/+analysis
      -> +gamrywb/+plot
      -> +gamrywb/+util
```

`apps/` should become thin launchers.

`+gamrywb/+app` should own app orchestration.

`+gamrywb/+ui` should own reusable UI component construction and small UI utilities.

`+gamrywb/+analysis`, `+gamrywb/+io`, and `+gamrywb/+plot` should remain independent of GUI state.

---

## 3. Proposed Package Areas

### 3.1 Add `+gamrywb/+app`

Create a new package folder:

```text
+gamrywb/+app/
```

Purpose:

- app launchers
- app-specific orchestration
- wiring UI callbacks to package functions
- small app-specific controller helpers

Candidate files:

```text
+gamrywb/+app/launchChronoOverlayApp.m
+gamrywb/+app/launchEISApp.m
+gamrywb/+app/launchVTResistanceApp.m
+gamrywb/+app/launchCICApp.m
+gamrywb/+app/launchCSCApp.m
```

Each `apps/gamrywb_*_app.m` file should eventually become a thin wrapper:

```matlab
function varargout = gamrywb_EIS_app(varargin)
    [varargout{1:nargout}] = gamrywb.app.launchEISApp(varargin{:});
end
```

The first step does not need to move all code at once. Move one app at a time.

### 3.2 Expand `+gamrywb/+ui`

Current `+ui` contains result-table helpers and small UI utilities. It should grow into a component library.

Candidate reusable UI builders:

```text
+gamrywb/+ui/createTwoPaneShell.m
+gamrywb/+ui/createTabbedDualPlotShell.m
+gamrywb/+ui/createFilePanel.m
+gamrywb/+ui/createFolderFileButtons.m
+gamrywb/+ui/createLogArea.m
+gamrywb/+ui/createResultTable.m
+gamrywb/+ui/createInfoGrid.m
+gamrywb/+ui/createTopBottomPlotPanel.m
+gamrywb/+ui/createPlotOptionRow.m
+gamrywb/+ui/appendLog.m
+gamrywb/+ui/refreshListboxItems.m
+gamrywb/+ui/showLoadError.m
```

These helpers should return handles in a struct, not rely on globals.

Example style:

```matlab
ui = gamrywb.ui.createTwoPaneShell(fig, opts);
ui.filePanel = gamrywb.ui.createFilePanel(parent, opts);
ui.log = gamrywb.ui.createLogArea(parent, "GUI started.");
```

Avoid a heavy generic framework. Start with small builders that remove obvious duplication.

---

## 4. Recommended Abstraction Levels

### Level 1: UI primitives

Small, low-risk helpers:

- create labeled edit field row
- create dropdown row
- create checkbox row
- create timestamped log append
- create axes with title/xlabel/ylabel
- disable axes interactivity
- normalize listbox selection

These are safest and should be extracted first.

### Level 2: Shared panels

Moderate helpers:

- file loading panel
- log panel
- result table panel
- info-summary panel
- top/bottom plot control panel
- left tab group with Files + Analysis / Summary + Results / Log

These should be extracted after at least two apps prove the same pattern.

### Level 3: App shells

High-value layout skeletons:

```text
TwoPaneShell
  left controls
  right plot area
```

Used by:

- Chrono overlay
- EIS overlay

```text
TabbedDualPlotShell
  left tabbed controls/results/log
  separator
  right top/bottom plot area
```

Used by:

- CIC
- VT resistance
- possibly CSC after alignment

This is the best abstraction target.

### Level 4: App specs

Optional future layer.

Do not start here.

A future app spec might look like:

```matlab
spec = struct();
spec.name = "Gamry EIS Multi-DTA Plot GUI";
spec.sessionKind = "eis_overlay";
spec.loader = @gamrywb.data.makeEISItem;
spec.plotter = @gamrywb.plot.plotEISOverlay;
spec.exporter = @gamrywb.io.buildEISExportTable;
```

This may become useful later, but forcing a spec-driven framework too early would over-abstract the code.

---

## 5. Recommended Refactor Order

### Phase A: Document current shared layout patterns

Create a small internal audit in this file or in code comments before moving code.

Group apps by layout pattern:

```text
Two-pane multi-file overlay apps:
- gamrywb_ChronoOverlay_app
- gamrywb_EIS_app

Tabbed dual-plot analysis apps:
- gamrywb_CIC_app
- gamrywb_VTResistance_app

Single-file dual-plot analysis app:
- gamrywb_CSC_app
```

Do not change runtime behavior in this phase.

### Phase B: Extract low-risk UI primitives

Extract helpers that cannot change scientific behavior:

```text
appendLog
createLabeledEditField
createLabeledDropdown
createAxes
refreshListboxItems
```

Acceptance criteria:

- no user-visible layout changes except code being cleaner
- GUI layout tests still pass
- default tests pass

Suggested commit:

```text
refactor: extract low-risk ui primitives
```

### Phase C: Extract common file/session panel behavior

Target repeated behavior in Chrono, EIS, CIC, and VT apps:

- open DTA files
- open folder recursively
- duplicate skipping
- add files through `gamrywb.data.addFilesToSession`
- clear all
- refresh listbox
- log add/skip/failure

Possible helper:

```text
+gamrywb/+ui/createFileSessionPanel.m
```

or split into:

```text
+gamrywb/+app/loadFilesIntoSession.m
+gamrywb/+ui/createFilePanel.m
```

Keep file dialogs in app/UI code, not in analysis/data code.

Acceptance criteria:

- Chrono and EIS still load and list files the same way
- duplicate skip behavior remains
- log wording remains stable unless intentionally updated
- GUI tests pass

Suggested commit:

```text
refactor: extract shared file session ui helpers
```

### Phase D: Extract TwoPaneShell

Start with the simpler apps:

- Chrono overlay
- EIS overlay

Extract their shared shell:

```text
+gamrywb/+ui/createTwoPaneShell.m
```

Expected return struct:

```matlab
ui.fig
ui.main
ui.leftPanel
ui.leftGrid
ui.rightPanel
ui.rightGrid
```

Do not hide too much. The app should still decide which controls and axes to place inside the shell.

Acceptance criteria:

- Chrono overlay and EIS app still launch
- component counts in GUI tests remain correct
- initial axes titles/labels remain correct
- export behavior unchanged

Suggested commit:

```text
refactor: extract two-pane app shell
```

### Phase E: Extract TabbedDualPlotShell

Target:

- CIC
- VT resistance

Both have the same broad structure:

```text
main 1x3 grid
left controls tab group
thin separator
right top/bottom plot area
```

Extract:

```text
+gamrywb/+ui/createTabbedDualPlotShell.m
```

Expected return struct:

```matlab
ui.fig
ui.main
ui.leftPanel
ui.tabs
ui.filesAnalysisTab
ui.summaryResultsTab
ui.logTab
ui.rightPanel
ui.topControlsPanel
ui.topAxes
ui.bottomControlsPanel
ui.bottomAxes
```

Keep app-specific settings and summary rows in the app for now.

Acceptance criteria:

- CIC and VT GUI contract tests pass
- draggable separator behavior is preserved if kept
- top/bottom plot controls still work
- reset/swap/refresh behavior unchanged

Suggested commit:

```text
refactor: extract tabbed dual-plot app shell
```

### Phase F: Extract top/bottom plot control helpers

CIC, VT, and CSC all create top/bottom plot selectors.

Candidate helper:

```text
+gamrywb/+ui/createXYPlotControlPanel.m
```

or:

```text
+gamrywb/+ui/createTopBottomPlotControls.m
```

Keep the item lists app-specific:

- chrono apps use Time/Sample and VT/IT
- CSC uses parsed curve column names
- EIS uses arbitrary EIS axis dropdowns and does not need dual plot controls

Suggested commit:

```text
refactor: extract shared dual-plot controls
```

### Phase G: Move app bodies into `+gamrywb/+app`

After UI shells exist, move app bodies out of `apps/`.

Target final shape:

```text
apps/gamrywb_CIC_app.m                 thin entry wrapper
+gamrywb/+app/launchCICApp.m           real app assembly
+gamrywb/+ui/...                       reusable components
```

Do one app at a time.

Recommended order:

1. EIS
2. Chrono overlay
3. VT resistance
4. CIC
5. CSC

Reason:

- EIS and Chrono are simpler two-pane apps.
- VT and CIC share more complex tabbed dual-plot scaffolding.
- CSC is single-file and has special curve/column behavior.

Suggested commit pattern:

```text
refactor: move EIS app assembly into gamrywb.app
refactor: move chrono overlay app assembly into gamrywb.app
refactor: move VT resistance app assembly into gamrywb.app
refactor: move CIC app assembly into gamrywb.app
refactor: move CSC app assembly into gamrywb.app
```

---

## 6. Design Rules For The Framework

### 6.1 Keep framework functions handle-based

Return structs of handles:

```matlab
ui = struct();
ui.fig = fig;
ui.leftPanel = leftPanel;
ui.axTop = axTop;
```

Do not introduce classes yet.

### 6.2 Keep scientific behavior out of UI builders

UI builders may create controls and panels.

They must not compute:

- CIC
- CSC
- VT resistance
- pulse detection
- EIS values
- parser outputs

### 6.3 Keep file IO boundaries explicit

Allowed in app/UI layer:

- `uigetfile`
- `uigetdir`
- `uiputfile`
- `uialert`

Not allowed in analysis functions:

- UI dialogs
- alerts
- direct control reads
- direct control writes

### 6.4 Avoid over-generalization

Do not create a universal generic app engine yet.

Prefer:

```text
small repeated helper extracted after two or more apps prove the pattern
```

over:

```text
large abstract framework designed before use
```

### 6.5 Preserve GUI test contracts

The GUI layout tests currently encode important compatibility expectations.

When extracting a shell or component, the resulting GUI should still satisfy:

- figure title
- minimum size
- button texts
- dropdown items
- checkbox texts
- result table columns
- axes titles and labels
- safe callbacks on empty state

If a layout change is intentional, update tests and document why.

---

## 7. Testing Strategy

After each extraction run:

```bash
scripts/run_matlab_tests.sh
```

When GUI construction changes, also run:

```bash
scripts/run_matlab_tests.sh --gui
```

Add new unit-level tests for UI helpers only when practical. For most MATLAB UI builder functions, the existing noninteractive GUI tests may be the main regression guard.

Recommended new tests:

```text
test_ui_primitives.m
test_ui_shells.m
```

Possible checks:

- shell functions return required handle fields
- panels and axes are created with expected titles
- log append preserves previous lines and adds timestamp prefix
- listbox refresh preserves valid selections
- empty file/session states are safe

Do not make tests too brittle about exact internal grid object counts unless that is an intentional compatibility contract.

---

## 8. Acceptance Criteria For This Stage

This stage is successful when:

- `apps/` files become thin wrappers or much smaller entry points.
- Large repeated layout scaffolds move into `+gamrywb/+ui` shell/component helpers.
- App-specific orchestration moves into `+gamrywb/+app`.
- CIC and VT share a tabbed dual-plot shell.
- Chrono and EIS share a two-pane shell.
- File/session/log/listbox behavior is not copy-pasted across every app.
- GUI layout contract tests still pass.
- Scientific tests still pass.
- No parser, analysis, plotting result, or export format changes occur unless explicitly requested.

---

## 9. Recommended First Agent Task

Start with a small, low-risk task:

```text
Extract shared UI primitives used by multiple apps.
```

Suggested first helpers:

```text
+gamrywb/+ui/appendLog.m
+gamrywb/+ui/createLabeledDropdown.m
+gamrywb/+ui/createLabeledEditField.m
+gamrywb/+ui/refreshListboxItems.m
```

Then apply only `appendLog` and simple labeled-row helpers to one or two apps first.

Do not attempt to extract the full shell in the first commit.

Suggested first commit:

```text
refactor: extract shared ui primitives
```

Then run:

```bash
scripts/run_matlab_tests.sh
scripts/run_matlab_tests.sh --gui
```

If MATLAB GUI support is unavailable, report that GUI tests were not run.

---

## 10. Summary

Current state:

```text
package-backed apps exist, but app GUI construction is still monolithic and repetitive
```

Next desired state:

```text
thin app entry points + reusable app shells + small UI components + package-backed analysis
```

Do not jump to a unified workbench GUI. First build the reusable pieces that would make a future unified workbench safe and maintainable.
