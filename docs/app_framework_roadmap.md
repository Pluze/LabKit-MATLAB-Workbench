# App Framework Roadmap

This roadmap describes the next refactor stage for Gamry Electrochemistry Workbench.

The project has already passed the legacy-removal checkpoint:

- Runtime entry points live in `apps/`.
- Root-level original GUI command wrappers are removed.
- The old `legacy/` GUI directory is removed.
- App files call `+gamrywb` parser, data, analysis, plotting, export, session, and UI helpers directly.
- Current GUI contracts are covered by default tests plus optional noninteractive GUI tests.

The next design problem is therefore not legacy replacement. The next design problem is app framework extraction: the app files still repeat layout, callback, logging, file/session, table, and plot scaffolding.

Goal:

```text
make future apps easier to build by extracting reusable GUI/application components
without changing scientific behavior, GUI contracts, or exported results
```

Non-goals:

```text
do not build a unified workbench GUI yet
do not convert structs to MATLAB classes
do not introduce a generic app engine before repeated patterns are proven
```

---

## 1. Current State

### 1.1 What is already complete

Completed app-entrypoint work:

- `apps/gamrywb_ChronoOverlay_app.m`
- `apps/gamrywb_EIS_app.m`
- `apps/gamrywb_CSC_app.m`
- `apps/gamrywb_VTResistance_app.m`
- `apps/gamrywb_CIC_app.m`

Completed package areas:

- `+gamrywb/+app`: initial app/session orchestration helper for duplicate-aware file loading.
- `+gamrywb/+analysis`: pulse detection and scientific analysis.
- `+gamrywb/+io`: parsers, result/export table builders, CSV writers, session IO.
- `+gamrywb/+data`: item/session construction and access helpers.
- `+gamrywb/+plot`: reusable plot helpers.
- `+gamrywb/+ui`: batch table display helpers, small axes helpers, log/listbox helpers, and simple labeled control helpers.
- `+gamrywb/+util`: low-risk utility helpers.

Current shared UI helpers:

```text
+gamrywb/+ui/clearAxisObjects.m
+gamrywb/+ui/disableAxesInteractivity.m
+gamrywb/+ui/hardResetAxis.m
+gamrywb/+ui/resetTopBottomAxes.m
+gamrywb/+ui/appendLog.m
+gamrywb/+ui/refreshListboxItems.m
+gamrywb/+ui/refreshFileListbox.m
+gamrywb/+ui/refreshSingleSelectFileListbox.m
+gamrywb/+ui/createAxes.m
+gamrywb/+ui/createLabeledDropdown.m
+gamrywb/+ui/createLabeledEditField.m
+gamrywb/+ui/createReadOnlyInfoRow.m
+gamrywb/+ui/createTwoPaneShell.m
+gamrywb/+ui/createTabbedDualPlotShell.m
+gamrywb/+ui/createTopBottomPlotControls.m
+gamrywb/+ui/setTopBottomPlotSelections.m
+gamrywb/+ui/swapTopBottomPlotSelections.m
+gamrywb/+ui/createFilePanel.m
+gamrywb/+ui/createSingleSelectFilePanel.m
+gamrywb/+ui/createInfoArea.m
+gamrywb/+ui/createLogArea.m
+gamrywb/+ui/createLogPanel.m
+gamrywb/+ui/createResultTablePanel.m
+gamrywb/+ui/createPlotOptionsPanel.m
+gamrywb/+ui/buildCICBatchTableData.m
+gamrywb/+ui/buildVTResistanceBatchTableData.m
```

This means the project has moved from:

```text
monolithic legacy GUI scripts
```

to:

```text
package-backed apps with repeated app scaffolding
```

That is a good intermediate state. The remaining work is to reduce repetition without weakening behavior preservation.

### 1.2 Current app patterns

The current apps mostly follow this implicit pattern:

```text
app entry point
  -> validate unsupported inputs/outputs
  -> initialize S state struct
  -> create uifigure
  -> create controls, tables, logs, and axes
  -> define nested callbacks
  -> callbacks call +gamrywb package helpers
  -> callbacks update UI widgets directly
```

Current layout groups:

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

### 1.3 Current weakness

Each app still owns too much framework code directly.

Repeated areas:

- input/output argument checks
- timestamped log append
- file-open and folder-open callbacks
- duplicate file handling
- `gamrywb.data.addFilesToSession(...)` wiring
- listbox refresh and selection restoration
- clear-all behavior
- common result-table setup
- top/bottom plot controls
- axes initialization and reset
- safe empty-session callbacks
- left/right or tabbed layout shells

These are framework concerns, not scientific analysis concerns.

---

## 2. Design Direction

Introduce a small functional app framework layer.

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

Target shape:

```text
apps/gamrywb_EIS_app.m              thin entry wrapper
+gamrywb/+app/launchEISApp.m       app assembly and callback wiring
+gamrywb/+ui/...                   reusable UI components and small UI utilities
```

Keep the framework:

- function-based
- struct-based
- explicit about handles
- conservative about UI side effects
- compatible with current GUI layout tests

Do not introduce classes yet.

---

## 3. Dynamic Adjustment Rules

This roadmap should be adjusted as extraction work reveals better boundaries.

Use these rules:

1. Extract only after at least two call sites prove the pattern, unless the helper is trivial and behavior-neutral.
2. Prefer small helpers before shells.
3. Keep scientific functions independent from UI state.
4. Keep UI builders handle-based and return structs of handles.
5. Preserve GUI contract tests by default.
6. If a helper makes an app harder to read, stop and revert or narrow the helper.
7. If a planned phase requires broad edits across three or more apps, split it.
8. If GUI tests need updates, document whether the changed surface is intentional.
9. Keep app-specific scientific wording, labels, table columns, and export names out of generic helpers.
10. Reorder phases when a lower-risk repeated pattern becomes obvious.

When expectations change, update this roadmap in the same commit or a nearby documentation commit.

---

## 4. Package Areas

### 4.1 `+gamrywb/+app`

This package now exists for reusable app/session orchestration helpers.

Purpose:

- app launch orchestration
- app-specific state setup
- callback wiring
- app-specific controller helpers

Already present:

```text
gamrywb/+app/loadFilesIntoSession.m
gamrywb/+app/removeSelectedItemsFromSession.m
gamrywb/+app/selectItemsByNames.m
gamrywb/+app/handleSingleFileSelection.m
gamrywb/+app/handleClearSingleFileSession.m
gamrywb/+app/launchChronoOverlayApp.m
gamrywb/+app/launchEISApp.m
gamrywb/+app/launchVTResistanceApp.m
gamrywb/+app/launchCICApp.m
gamrywb/+app/launchCSCApp.m
```

Candidate files:

```text
+gamrywb/+app/launchChronoOverlayApp.m
+gamrywb/+app/launchEISApp.m
+gamrywb/+app/launchVTResistanceApp.m
+gamrywb/+app/launchCICApp.m
+gamrywb/+app/launchCSCApp.m
```

Final wrapper style:

```matlab
function varargout = gamrywb_EIS_app(varargin)
    [varargout{1:nargout}] = gamrywb.app.launchEISApp(varargin{:});
end
```

Do one app at a time.

### 4.2 `+gamrywb/+ui`

`+ui` should contain reusable UI helpers and layout components.

Already present:

```text
buildCICBatchTableData
buildVTResistanceBatchTableData
appendLog
refreshListboxItems
refreshFileListbox
createAxes
createLabeledDropdown
createLabeledEditField
createTwoPaneShell
createFilePanel
createInfoArea
createLogArea
createPlotOptionsPanel
clearAxisObjects
disableAxesInteractivity
hardResetAxis
```

Next candidates:

```text
createResultTable
```

Helpers should return handle structs:

```matlab
ui = struct();
ui.panel = panel;
ui.grid = grid;
ui.controls = controls;
```

Avoid hidden globals or persistent app state.

---

## 5. Refactor Levels

### Level 1: UI primitives

Low risk. Extract first.

Examples:

- append a timestamped log line
- create labeled edit-field rows
- create labeled dropdown rows
- create axes with title/xlabel/ylabel
- refresh listbox items and preserve selection when possible
- clear/reset axes
- disable axes interactivity

Status:

```text
partial: axes clear/reset/interactivity, log append, listbox refresh, and simple labeled controls are extracted
remaining: create axes helpers and larger shared panels/shells
```

### Level 2: Shared panels

Moderate risk. Extract after primitives.

Examples:

- file loading panel
- log panel
- result table panel
- info-summary panel
- top/bottom plot control panel
- left tab group with Files + Analysis / Summary + Results / Log

Rule:

```text
extract a panel only when at least two apps use the same panel shape
```

### Level 3: App shells

High value. Extract after app panel shapes are stable.

Two-pane shell:

```text
left controls
right plot area
```

Target apps:

- Chrono overlay
- EIS overlay

Tabbed dual-plot shell:

```text
left tabbed controls/results/log
separator
right top/bottom plot area
```

Target apps:

- CIC
- VT resistance

CSC should remain separate until its single-file curve/column behavior is better isolated.

### Level 4: App launchers

App bodies now live in `+gamrywb/+app`, leaving `apps/` as public entry wrappers.

Target order:

1. EIS: done
2. Chrono overlay: done
3. VT resistance: done
4. CIC: done
5. CSC: done

Reason:

- EIS and Chrono have simpler two-pane structure.
- VT and CIC share the complex tabbed dual-plot structure.
- CSC has special single-file curve/column behavior.

### Level 5: Optional app specs

Do not start here.

A future spec may become useful:

```matlab
spec = struct();
spec.name = "Gamry EIS Multi-DTA Plot GUI";
spec.sessionKind = "eis_overlay";
spec.loader = @gamrywb.data.makeEISItem;
spec.plotter = @gamrywb.plot.plotEISOverlay;
spec.exporter = @gamrywb.io.buildEISExportTable;
```

Only introduce this if shell/helper extraction leaves clear repeated app metadata.

---

## 6. Recommended Phase Plan

### Phase A: Baseline audit

Status: complete enough to proceed.

Evidence:

- all runtime apps are under `apps/`
- `legacy/` is absent
- GUI tests cover launch/layout contracts
- this roadmap now groups current app layout patterns

### Phase B: Finish low-risk UI primitives

Status: in progress.

Already done:

- `clearAxisObjects`
- `disableAxesInteractivity`
- `hardResetAxis`
- `appendLog`
- `refreshListboxItems` for multiselect file listboxes
- `createLabeledDropdown` and `createLabeledEditField` for Chrono/EIS plot option rows

Next helpers:

```text
+gamrywb/+ui/createAxes.m
```

Recommended commit:

```text
refactor: extract ui primitive helpers
```

Acceptance criteria:

- no visible GUI layout changes
- log wording remains stable
- dropdown values and callbacks remain stable
- default tests pass
- GUI tests pass

### Phase C: Extract file/session behavior

Status: started.

Target repeated behavior:

- open files
- open folder recursively
- skip duplicates: started with `gamrywb.app.loadFilesIntoSession`
- add files through `gamrywb.data.addFilesToSession`: started with `gamrywb.app.loadFilesIntoSession`
- remove selected files: started with `gamrywb.app.removeSelectedItemsFromSession`
- selected item lookup: started with `gamrywb.app.selectItemsByNames`
- clear session
- refresh file listbox: done for Chrono/EIS with `gamrywb.ui.refreshFileListbox`
- log add/skip/failure

Preferred split:

```text
+gamrywb/+app/loadFilesIntoSession.m    done for Chrono/EIS overlay apps
+gamrywb/+app/removeSelectedItemsFromSession.m    done for Chrono/EIS overlay apps
+gamrywb/+app/selectItemsByNames.m    done for Chrono/EIS overlay apps
+gamrywb/+app/handleSingleFileSelection.m    done for VT resistance and CIC apps
+gamrywb/+app/handleClearSingleFileSession.m    done for VT resistance and CIC apps
+gamrywb/+ui/refreshListboxItems.m
+gamrywb/+ui/refreshFileListbox.m    done for Chrono/EIS overlay apps
+gamrywb/+ui/refreshSingleSelectFileListbox.m    done for VT resistance and CIC apps
+gamrywb/+ui/createSingleSelectFilePanel.m    done for VT resistance and CIC apps
+gamrywb/+ui/createReadOnlyInfoRow.m    done for VT resistance and CIC summary rows
+gamrywb/+ui/createLogPanel.m    done for VT resistance and CIC log tabs
+gamrywb/+ui/setTopBottomPlotSelections.m    done for VT resistance and CIC apps
+gamrywb/+ui/swapTopBottomPlotSelections.m    done for VT resistance and CIC apps
+gamrywb/+ui/resetTopBottomAxes.m    done for VT resistance and CIC apps
+gamrywb/+ui/createResultTablePanel.m    done for VT resistance and CIC apps
```

Keep dialogs in app/UI code. Keep `gamrywb.data.addFilesToSession` free of UI dialogs.

Recommended first targets:

1. Chrono overlay
2. EIS

Reason:

- both are multi-file overlay apps
- both have similar listbox/file workflows
- lower risk than CIC/VT analysis apps

### Phase D: Extract two-pane shell

Status: started.

Target apps:

- Chrono overlay
- EIS

Helper:

```text
+gamrywb/+ui/createTwoPaneShell.m    done for Chrono/EIS overlay apps
+gamrywb/+ui/createFilePanel.m    done for Chrono/EIS overlay apps
+gamrywb/+ui/createInfoArea.m    done for Chrono/EIS overlay apps
+gamrywb/+ui/createLogArea.m    done for Chrono/EIS overlay apps
+gamrywb/+ui/createPlotOptionsPanel.m    done for Chrono/EIS overlay apps
+gamrywb/+ui/createAxes.m    done for Chrono/EIS overlay apps
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

Keep app-specific controls and axes outside the shell.
The shared files panel owns only the common button layout and callback wiring surface; dialogs and load/export behavior stay in app code.
The shared info/log helpers own only the common read-only text-area placement and initial values.
The shared plot-options panel owns only the common panel/grid shell; app-specific controls, defaults, and callbacks stay in app code.
The shared axes helper owns only initial axes creation, layout row, and labels.

Acceptance criteria:

- figure titles unchanged
- minimum sizes unchanged
- component counts unchanged unless intentionally documented
- initial axes labels unchanged
- export behavior unchanged

### Phase E: Extract tabbed dual-plot shell

Status: complete.

Target apps:

- CIC
- VT resistance

Candidate helper:

```text
+gamrywb/+ui/createTabbedDualPlotShell.m    done for VT resistance and CIC apps
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

Keep app-specific analysis settings, summary rows, and result tables in app code for the first extraction.
VT resistance and CIC now use the shared shell while keeping app-specific controls, defaults, and callbacks in app code.

Acceptance criteria:

- CIC and VT GUI contract tests pass
- draggable separator behavior is preserved if included
- top/bottom plot controls still work
- reset/swap/refresh behavior unchanged

### Phase F: Extract top/bottom plot controls

Status: complete.

Target apps:

- CIC
- VT resistance
- possibly CSC

Candidate helper:

```text
+gamrywb/+ui/createTopBottomPlotControls.m    done for VT resistance and CIC apps
```

Keep dropdown item lists app-specific.
VT resistance and CIC now use the shared control helper while keeping app-specific dropdown item lists, defaults, callbacks, and labels in app code.

### Phase G: Move app bodies into `+gamrywb/+app`

Status: complete.

Shell/helper extraction has improved the Chrono/EIS overlay app bodies enough to start moving app assembly one app at a time.

Commit sequence:

```text
refactor: move chrono overlay app assembly into gamrywb.app    done
refactor: move EIS app assembly into gamrywb.app    done
refactor: move VT resistance app assembly into gamrywb.app    done
refactor: move CIC app assembly into gamrywb.app    done
refactor: move CSC app assembly into gamrywb.app    done
```

Each commit should keep the public `apps/gamrywb_*_app.m` entry point intact.
The public app file should be a thin wrapper that calls the matching `gamrywb.app.launch*App` function.

---

## 7. Testing Strategy

After documentation-only roadmap edits:

```text
no MATLAB test required unless source or tests changed
```

After MATLAB source changes:

```bash
scripts/run_matlab_tests.sh
```

When GUI construction or app entry points change:

```bash
scripts/run_matlab_tests.sh --gui
```

Add focused tests when practical:

```text
test_ui_primitives.m
test_ui_shells.m
test_app_entrypoints.m
```

Possible checks:

- helper returns expected fields
- panels and axes are created with expected titles
- log append preserves previous lines and adds timestamp prefix
- listbox refresh preserves valid selections
- empty file/session states are safe

Do not make tests brittle about internal grid object counts unless that surface is an intentional compatibility contract.

---

## 8. Acceptance Criteria For This Stage

This app-framework stage is successful when:

- `apps/` files are thin wrappers or much smaller entry points.
- App-specific orchestration lives under `+gamrywb/+app`.
- Large repeated layout scaffolds live under `+gamrywb/+ui`.
- CIC and VT share a tabbed dual-plot shell.
- CIC and VT share the single-select files panel.
- Chrono and EIS share a two-pane shell.
- File/session/log/listbox behavior is not copied across every app.
- GUI layout contract tests pass.
- Scientific tests pass.
- CSV/export formats remain unchanged.
- Parser, analysis, plotting result, and GUI label behavior remain unchanged unless explicitly requested.

---

## 9. Current Next Best Task

The next best task is:

```text
reassess remaining repeated CIC/VT callbacks and summary panels
```

Suggested sequence:

1. Compare the remaining CIC/VT single-file selection, clear-all, log, and summary-row helpers.
2. Pick the lowest-risk repeated behavior with at least two call sites.
3. Keep app-specific scientific labels, result columns, and export names outside generic helpers.

---

## 10. Route Adjustment Log

Use this section to record meaningful changes in strategy.

```text
2026-05-29:
- legacy replacement is no longer the main problem; legacy is removed
- all app entry points are package-backed
- axes clear/reset/interactivity helpers are already extracted into +gamrywb/+ui
- next route changed from "extract first primitives" to "finish remaining low-risk primitives, then file/session behavior"
- appendLog is now extracted and used by all app entry points
- refreshListboxItems is extracted for Chrono/EIS multiselect file listboxes
- refreshFileListbox shares session-item-to-listbox refresh for Chrono/EIS
- createLabeledDropdown and createLabeledEditField are extracted for Chrono/EIS plot option rows
- createTwoPaneShell starts Phase D by sharing the Chrono/EIS outer two-pane shell while keeping app-specific controls and axes in app files
- createFilePanel shares the Chrono/EIS files button panel while keeping dialogs and export behavior in app files
- createInfoArea and createLogArea share Chrono/EIS read-only text-area placement while preserving app-specific info copy
- createPlotOptionsPanel shares the Chrono/EIS plot-options panel shell while preserving app-specific controls and callbacks
- createAxes shares Chrono/EIS initial axes construction while preserving labels
- createTabbedDualPlotShell shares the VT/CIC outer tabbed dual-plot shell; VT resistance and CIC both use it
- createTopBottomPlotControls shares the VT/CIC top/bottom plot control rows; VT resistance and CIC both use it
- launchChronoOverlayApp moves the first app body under +gamrywb/+app while keeping apps/gamrywb_ChronoOverlay_app.m as the public wrapper
- launchEISApp moves the EIS app body under +gamrywb/+app while keeping apps/gamrywb_EIS_app.m as the public wrapper
- launchVTResistanceApp moves the VT resistance app body under +gamrywb/+app while keeping apps/gamrywb_VTResistance_app.m as the public wrapper
- launchCICApp moves the CIC app body under +gamrywb/+app while keeping apps/gamrywb_CIC_app.m as the public wrapper
- launchCSCApp moves the CSC app body under +gamrywb/+app while keeping apps/gamrywb_CSC_app.m as the public wrapper; Phase G is complete
- loadFilesIntoSession starts the +gamrywb/+app layer for duplicate-aware file/session loading in Chrono/EIS
- removeSelectedItemsFromSession shares selected-file removal for Chrono/EIS while preserving app-owned refresh and plotting
- selectItemsByNames shares empty-selection-as-all item lookup for Chrono/EIS plot and export paths
- handleSingleFileSelection shares the VT/CIC single-file selection callback sequence while keeping reset, summary, and plot behavior app-owned
- handleClearSingleFileSession shares the VT/CIC clear-all session reset sequence while applying app state before app-owned refresh callbacks
- createSingleSelectFilePanel shares the VT/CIC files panel while preserving app-owned dialogs, selection refresh, and export behavior
- refreshSingleSelectFileListbox shares VT/CIC single-file listbox refresh and loaded-count text while returning the app-owned current index
- createReadOnlyInfoRow shares VT/CIC summary-row label/read-only-field construction while keeping app-specific labels and state fields in app code
- setTopBottomPlotSelections, swapTopBottomPlotSelections, and resetTopBottomAxes share VT/CIC top/bottom plot-control state behavior while preserving app-owned refresh calls
- createResultTablePanel shares VT/CIC batch-result table panel construction while keeping app-specific column names and table data in app code
- createLogPanel shares VT/CIC log-tab panel construction while preserving app-owned appendLog calls and message text
```

---

## 11. Summary

Current state:

```text
package-backed apps exist, legacy is removed, but app GUI construction is still monolithic and repetitive
```

Next desired state:

```text
thin app entry points + gamrywb.app launchers + reusable UI shells + small UI components
```

Do not jump to a unified workbench GUI. First build the reusable pieces that make future app consolidation safe and maintainable.
