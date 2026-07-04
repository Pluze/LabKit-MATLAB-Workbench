# LabKit UI Utilities, Plot Popout, and State Snapshot Design

Status: design artifact, not an implemented public contract
Date: 2026-07-04
Scope: framework-level UI utilities for plot popout/edit/export, app screenshots, and app state snapshots

## Executive Summary

This proposal adds a narrow framework layer for three recurring needs:

1. Enhanced plot popout windows that are useful for publication cleanup: font size, line width, copy/export, graphics-object data export, and generated MATLAB script.
2. App-level state snapshots saved as `.mat` files, constrained to the same LabKit version, app version, MATLAB release, and environment.
3. A small workbench utility bar that exposes framework-owned actions such as pop out current plot, screenshot, save state, and load state.

The important boundary is that the framework should own generic UI mechanics, while apps continue to own experiment vocabulary, calculations, result schemas, domain-specific exports, and user workflow wording. The generated plot script should reproduce the visible graphics object tree, not the original scientific analysis pipeline. The state snapshot should restore an interactive task state, not become a provenance or raw-data archive format.

Recommended rollout:

1. Implement enhanced `labkit.ui.tool.popoutAxes` first, because it is isolated and already exists.
2. Add app snapshot save/load APIs with strict serialization checks and optional app hooks.
3. Add the workbench utility bar after the two underlying services are stable.

## Research Inputs

The search focused on MATLAB-native features, mature MATLAB scientific projects, and popular scientific GUI/script ecosystems.

| Source | Pattern observed | Design lesson for LabKit |
| --- | --- | --- |
| MathWorks `exportgraphics` | Exports axes, figures, chart layouts, and containers; supports file output, vector/image content, resolution, padding, and dimensions. | Use MATLAB-native graphics export for plot/image outputs instead of custom render pipelines. |
| MathWorks `copygraphics` | Copies axes/figures/chart layouts to the system clipboard with content-type and resolution options. | Use for plot/axes clipboard actions; whole-app clipboard should be treated as best effort. |
| MathWorks `exportapp` | Captures `uifigure` or App Designer apps as JPEG, PNG, TIFF, or PDF, including UI components. | Use for app screenshot-to-path because it captures UI components, not just axes. |
| MathWorks `save` / MAT files | Supports saving selected variables or structures to `.mat`, with version choices including v7.3. | Store one explicit `snapshot` variable, not the full runtime appdata blob. |
| MathWorks `uitoolbar` / `uipushtool` | MATLAB supports figure/uifigure toolbars with push/toggle tools. | Popout and app-level utility actions should be command surfaces, not app-specific button clutter. |
| EEGLAB data structures and history | EEGLAB keeps transparent MATLAB structs, explicit function inputs, and command history for scripting. | Prefer struct snapshots and explicit replayable commands over class-heavy hidden state. |
| FieldTrip data structures | FieldTrip uses MATLAB structs with data fields plus metadata, then checks/converts them at function entry. | Snapshot load should validate schema/version and normalize before restoration. |
| ImageJ recorder and utilities | ImageJ records UI commands into macros and provides screenshot/capture utilities. | LabKit should make GUI work reproducible enough to generate a graph-level script, but avoid pretending every GUI action is replayable. |
| JupyterLab workspaces | Workspaces save UI layout/state separately as a schema with metadata and import/export validation. | Separate app semantic state from layout/view preferences; validate identity before load. |
| Matplotlib explicit Axes API | The explicit axes object is the stable customization surface; implicit state is convenient but less robust. | LabKit popout APIs should operate on explicit axes handles and generated script should reconstruct axes explicitly. |
| Pylustrator | GUI figure edits can be saved as generated plotting code for reproducible publication figures. | A useful target is "visible figure plus generated code", but LabKit should generate standalone code rather than mutate source files. |
| napari Viewer API | The viewer exposes screenshot/export methods and stores visualization controls such as contrast, colormap, and gamma as view-layer properties. | Visual mapping and export tools belong in UI/view services; they should not mutate underlying scientific data. |

Source URLs are listed at the end of this document.

## Current LabKit Position

Current relevant framework pieces:

- `labkit.ui.tool.enableAxesPopout(ax)` installs a context-menu item on an axes and its children.
- `labkit.ui.tool.popoutAxes(srcAx)` copies a UI axes into a standalone MATLAB `figure`, copies axes state, copies children, labels, grid/color settings, and preserves image aspect ratio.
- `labkit.ui.app.run(def, request)` stores runtime appdata as a struct containing `definition`, `state`, `actions`, `ui`, and `debug`.
- `labkit.ui.app.private.createTabbedWorkbenchShell` owns the primary app shell grid, currently with startup status row plus main content row.
- `previewArea` creates axes and already enables axes popout.

The runtime appdata must not be saved directly because it contains live UI handles, function handles, listeners, debug structures, and other environment-specific objects. A state snapshot needs a separate serializable contract.

## Design Principles

1. Keep `+labkit` small and domain-neutral.
2. Keep the public API narrow; use private helpers for extraction, serialization checks, and script generation.
3. Save app state, not MATLAB object handles.
4. Generated plot scripts reproduce visible graphics, not app computations.
5. Screenshots are visual artifacts; snapshots are task-resume artifacts; scientific exports remain app-owned.
6. Prefer explicit schema validation and loud failure over partial restoration.
7. Do not convert app lifecycle or state models to MATLAB classes for this feature set.
8. Workbench utilities should be framework affordances that every app gets consistently, not copied buttons inside each app.

## Top-Down Architecture

The design has three public capability surfaces and one private service layer.

```text
User command
  |
  +-- Workbench utility bar
  |     |
  |     +-- labkit.ui.app service commands
  |           +-- screenshot app
  |           +-- save/load app state
  |           +-- find current axes and delegate plot commands
  |
  +-- Axes context menu
        |
        +-- labkit.ui.tool popout command
              +-- copied figure
              +-- figure style commands
              +-- graphics data export
              +-- recreate-plot script generation
```

Layer responsibilities:

| Layer | Owns | Must not own |
| --- | --- | --- |
| App definition | App identity, state factory, command handlers, render function, optional snapshot hooks. | Generic shell buttons, axes-copy mechanics, screenshot plumbing. |
| `labkit.ui.app` | Workbench shell, utility bar, active axes lookup, app screenshots, app state snapshot lifecycle. | Domain exports, result schemas, scientific calculations. |
| `labkit.ui.tool` | Axes-level tools: context menu, popout figure, copied-figure styling, visible graphics data/script export. | App runtime state, app-specific result tables, raw experiment exports. |
| Private helpers | Serialization validation, graphics-object extraction, generated script writing, chooser injection for tests. | New public facade vocabulary until repeated usage proves the API. |

The central design move is to make user-facing conveniences framework-owned while keeping scientific interpretation app-owned. That prevents every app from inventing its own "copy plot", "save screenshot", "force redraw", and "save state" buttons, but it also avoids turning `+labkit` into a domain archive or analysis provenance system.

## Data Flow Summary

### Plot Popout and Export

```text
source axes in app
  -> copy axes state and children into standalone figure
  -> user edits copied figure style
  -> exportgraphics/copygraphics for visual output
  -> extract supported graphics objects
  -> write plot_data.mat plus optional CSV
  -> generate recreate_plot.m from exported data and style metadata
```

The copied figure is intentionally disconnected from app state. A user can make publication-oriented visual edits without mutating the underlying app plot or triggering app recomputation.

### App Snapshot

```text
runtime appdata
  -> runtime.state only
  -> optional app Serialize hook
  -> generic serializability validation
  -> snapshot metadata and state written as one MAT variable
```

Restore is the reverse:

```text
snapshot MAT
  -> schema/version/app identity validation
  -> optional app Deserialize hook
  -> validate restored state
  -> atomically replace runtime.state
  -> render
  -> optional app AfterLoad hook
```

Atomicity is required: if load fails at any step, current app state must remain unchanged.

### Utility Bar

```text
button click
  -> framework command dispatcher
  -> find runtime or current axes
  -> run app-level service or delegate to labkit.ui.tool
  -> report errors through labkit.ui.app.showAlert-compatible behavior
```

The utility bar should not call app command handlers unless the app explicitly opts into an `AfterLoad` or similar hook. Framework utilities act on framework-owned runtime and graphics surfaces.

## Design Decision Matrix

| Question | Decision | Rationale |
| --- | --- | --- |
| Should plot export live in apps? | No for visible graphics-object export; yes for scientific result exports. | The visible axes tree is domain-neutral. Recalculation-grade exports are app-owned. |
| Should snapshot save the whole runtime? | No. | Runtime includes handles and function handles that are environment-bound and unsafe to serialize. |
| Should `labkit.ui.snapshot` become a new facade? | No in v1. | The public surface is still small; `labkit.ui.app.saveState/loadState` is easier to discover. |
| Should popout use `figure` or `uifigure`? | Use normal `figure` in v1. | Existing behavior and MATLAB publication/export workflows already fit `figure`. |
| Should utility bar be app spec content? | No by default. | It is shell chrome, not app workflow content. |
| Should generated scripts replay GUI actions? | No. | Replaying arbitrary GUI actions is fragile. Reconstructing visible graphics is tractable and testable. |
| Should incompatible snapshots attempt migration? | No in v1. | The user requirement is same version and same environment; strict failure is clearer. |

## Capability 1: Enhanced Plot Popout

### User Experience

Existing right-click behavior should continue to work:

- Right-click a plot or plotted child.
- Choose `Open axes in new figure`.
- A standalone MATLAB figure opens with copied content.

The new popout figure should include a compact toolbar or command strip with:

- Increase/decrease font size.
- Increase/decrease line width.
- Copy plot to clipboard.
- Save plot image/PDF.
- Export visible plot data.
- Generate MATLAB script that recreates the visible plot.
- Optional reset-to-original styling.

The controls should edit the copied figure only. The app plot remains unchanged.

### Ownership

Framework-owned:

- Discover graphics children and extract generic graphics-object data.
- Apply generic style edits to axes labels, ticks, legends, colorbars, and line/scatter objects.
- Export plot graphics through `exportgraphics`.
- Copy plot graphics through `copygraphics`.
- Generate graph-level MATLAB recreation scripts.

App-owned:

- Domain labels and plot content.
- Analysis data and result schema exports.
- Any export that promises raw domain data or recalculatable scientific results.

### Public API

Extend the existing public API conservatively:

```matlab
newFig = labkit.ui.tool.popoutAxes(srcAx)
newFig = labkit.ui.tool.popoutAxes(srcAx, "Toolbar", true)
newFig = labkit.ui.tool.popoutAxes(srcAx, "Title", "Custom title")
```

Keep `enableAxesPopout(ax)` as the only app-facing installer. It can call the enhanced `popoutAxes` internally without requiring app changes.

Do not publish separate data-export/script-generation APIs in v1. Keep them private under `+labkit/+ui/+tool/private` until the schema is proven by tests and at least two app families.

### Popout Window Shape

Use a normal MATLAB `figure` for v1, matching current `popoutAxes`. Reasons:

- Existing implementation already uses `figure`.
- Publication export and figure editing workflows in MATLAB are strongest on normal figures.
- Existing tests already assert behavior for standalone figure popouts.

Add a lightweight toolbar with `uitoolbar` and `uipushtool` where possible. For controls that need numeric input, use a small modal dialog launched by toolbar buttons, or provide `A+`, `A-`, `LW+`, and `LW-` commands. A full custom `uifigure` style editor can wait until there is evidence that the toolbar workflow is too limited.

### Style Commands

Suggested commands:

```text
Font +        Increase axes, label, title, legend, colorbar font sizes by 1 pt
Font -        Decrease same, min 6 pt
Line +        Increase line/scatter/surface edge widths by 0.25 pt
Line -        Decrease same, min 0.25 pt
Style...      Dialog for explicit font size, line width, marker size
Copy          copygraphics(ax or fig)
Save          exportgraphics(ax or fig)
Data          export graphics-object data
Script        generate recreate_plot.m plus data file when needed
```

The style commands should traverse visible children and skip objects that do not support the target property.

### Data Extraction Schema

Create a private extractor that returns a struct:

```matlab
plotData = struct();
plotData.schema = "labkit.ui.tool.axesData.v1";
plotData.createdAt = datetime("now", "TimeZone", "local");
plotData.axes = axesMetadata;
plotData.objects = graphicsObjects;
plotData.warnings = strings(0, 1);
```

Each object entry:

```matlab
object = struct( ...
    "type", "line", ...
    "displayName", "Cycle 1 anodic", ...
    "x", x(:), ...
    "y", y(:), ...
    "z", z(:), ...
    "style", styleStruct, ...
    "metadata", metadataStruct);
```

Supported in v1:

- `Line`: `XData`, `YData`, optional `ZData`, `DisplayName`, color, line style, marker, line width.
- `Scatter`: `XData`, `YData`, optional `ZData`, marker size/color when available.
- `Image`: `CData`, `XData`, `YData`, `AlphaData`, colormap, clim. Export general image data to `.mat`, not CSV.
- `Surface`: optional if extraction is simple and tests can cover it.
- Legends/colorbars/labels: metadata and script reconstruction, not primary data tables.

Unsupported children should be skipped with a warning in the export manifest and generated script comments.

### Export Formats

Use a folder-level export for generality:

```text
selected_plot/
  plot_data.mat
  plot_data.csv          optional when all exported objects are 1-D line/scatter series
  recreate_plot.m
  README.txt             short machine-generated note and warnings
```

For simple line-only plots, `plot_data.csv` can be wide:

```text
pointIndex,objectName,x,y
1,Cycle 1 anodic,0.12,3.4e-6
...
```

or paired-wide when all series share the same x vector:

```text
x,Cycle 1 anodic y,Cycle 1 cathodic y,Cycle 2 anodic y
...
```

The extractor should prefer correctness over compactness:

- Shared x vector: one `x` column plus one y column per object.
- Non-shared x vector: one pair of x/y columns per object.
- Mixed object types: MAT export is authoritative; CSV is best-effort or omitted.

### Script Generation

Generated script should use explicit axes:

```matlab
data = load("plot_data.mat");
fig = figure("Color", "w");
ax = axes("Parent", fig);
hold(ax, "on");
% plot objects...
xlabel(ax, "...");
ylabel(ax, "...");
title(ax, "...");
legend(ax, "show", "Interpreter", "none");
```

Do not mutate source app files. Do not require LabKit to rerun the script unless the script intentionally loads only standard MATLAB data from `plot_data.mat`.

### Tests

Add or extend GUI framework tests:

- Right-click/context menu still exists.
- Popout figure opens in hidden GUI test mode.
- Existing image aspect-ratio behavior remains.
- Font and line-width commands change copied figure, not source axes.
- Line-only data export writes MAT and CSV.
- Mixed line/image export writes MAT and warnings.
- Generated script runs in MATLAB batch mode for simple line plots and creates a nonempty axes.

## Capability 2: App State Snapshot

### User Experience

The utility bar and public APIs should support:

- `Save State...`: write a `.mat` snapshot for the current app.
- `Load State...`: load a `.mat` snapshot and restore state if compatible.

V1 compatibility should be strict:

- Same app id.
- Same app version when available.
- Same LabKit UI facade version.
- Same snapshot schema version.
- Same or compatible MATLAB release.
- Same app snapshot schema version when an app declares one.

This matches the user's requirement: "same version, same environment".

### What Is Saved

Save one variable named `snapshot`:

```matlab
snapshot = struct();
snapshot.schema = "labkit.ui.app.snapshot.v1";
snapshot.createdAt = datetime("now", "TimeZone", "local");
snapshot.app = struct( ...
    "id", runtime.definition.id, ...
    "title", runtime.definition.title, ...
    "version", appVersionStringOrEmpty, ...
    "snapshotVersion", appSnapshotVersion);
snapshot.labkit = struct( ...
    "uiVersion", labkit.ui.version(), ...
    "matlabRelease", version("-release"), ...
    "platform", string(computer));
snapshot.state = serializedState;
snapshot.view = viewPreferences;
snapshot.warnings = strings(0, 1);
```

`snapshot.state` is the app semantic state after serialization. `snapshot.view` is optional framework-owned view preference state, such as selected file-panel entry, active preview mode, and axes viewport policy if safe to represent semantically. Do not store UI handles.

### Definition Hook

Extend `labkit.ui.app.define` with one optional name-value:

```matlab
def = labkit.ui.app.define( ...
    "Id", "example", ...
    "Title", "Example App", ...
    "InitialState", @example.appLifecycle.createInitialState, ...
    "Spec", @example.userInterface.buildWorkbenchSpec, ...
    "Actions", example.definitionActions(), ...
    "Render", @example.userInterface.updateWorkbenchFromState, ...
    "Snapshot", example.snapshot.spec());
```

Suggested app snapshot spec:

```matlab
spec = struct( ...
    "Version", 1, ...
    "Serialize", @example.snapshot.serialize, ...
    "Deserialize", @example.snapshot.deserialize, ...
    "AfterLoad", @example.snapshot.afterLoad);
```

All hooks are optional:

- No hook: framework saves state directly after generic serializability validation.
- `Serialize`: app can remove caches, handles, transient warnings, or large derived arrays.
- `Deserialize`: app can fill new defaults, validate file references, and normalize old same-version edge cases.
- `AfterLoad`: app can request redraw/recompute actions after framework state has been installed.

Do not add migration support in v1. If app version changed, fail with a clear message.

### Public API

Add two public app APIs:

```matlab
labkit.ui.app.saveState(fig)
labkit.ui.app.saveState(fig, filepath)
labkit.ui.app.loadState(fig)
labkit.ui.app.loadState(fig, filepath)
```

Dialogs use existing safe output/input default helpers. API functions use the current figure runtime appdata and throw `labkit:ui:app:*` errors for invalid or incompatible snapshots.

Keep lower-level helpers private:

- `createSnapshot`
- `validateSerializableState`
- `writeSnapshot`
- `readSnapshot`
- `restoreSnapshot`
- `snapshotRuntimeMetadata`

### Serializability Rules

Allow:

- numeric, logical, string, char
- struct and cell arrays containing allowed types
- table/timetable when variables are allowed types
- datetime, duration, calendarDuration, categorical
- missing, empty arrays

Reject by default:

- graphics handles
- timers
- listeners
- Java/.NET/Python objects
- function handles
- file identifiers
- opaque MATLAB objects unless explicitly whitelisted
- app runtime structs containing `ui`, `actions`, `definition`, or `debug`

When rejection occurs, report the state path, such as:

```text
state.preview.axesHandle is a graphics handle and cannot be saved.
```

### Load Flow

1. Choose file or accept filepath argument.
2. Load only `snapshot`.
3. Validate top-level schema.
4. Validate app id and versions.
5. Run app `Deserialize` hook if present.
6. Validate deserialized state shape.
7. Install `runtime.state`.
8. Restore framework view preferences where safe.
9. Call app render.
10. Run `AfterLoad` hook if present.
11. Log or alert warnings.

If any step fails, leave the current app state unchanged.

### Tests

Add framework tests:

- Round-trip simple struct state.
- Reject graphics handles with path-specific diagnostic.
- Reject function handles.
- Save file contains one `snapshot` variable.
- App id mismatch fails without mutating current state.
- Version mismatch fails.
- App `Serialize` and `Deserialize` hooks are called.
- Failed `Deserialize` leaves runtime state unchanged.

Add one representative GUI app test with a minimal app definition. Do not use real lab data.

## Capability 3: Workbench Utility Bar

### User Experience

Every UI 4.x workbench can show a compact top utility bar:

```text
[Pop Out] [Copy Plot] [Save Plot] [Screenshot] [Save State] [Load State]
```

The exact labels can be icon-first later, but commands should be stable and discoverable in tests by semantic id.

Default buttons:

- Pop out current plot.
- Copy current plot.
- Save current plot.
- Save app screenshot.
- Save state.
- Load state.

Optional second phase:

- Copy app screenshot to clipboard, if cross-platform reliability is acceptable.
- Export plot data and generated script directly from utility bar.

### Shell Integration

Current shell grid:

```text
row 1: startup status, height 0 when hidden
row 2: left controls | separator | right workspace
```

Proposed shell grid:

```text
row 1: utility bar, fixed height about 30 px
row 2: startup status, height 0 when hidden
row 3: left controls | separator | right workspace
```

The utility bar should be created by `labkit.ui.app` private shell code, not by each app spec. It should be configurable from app definition or app spec options:

```matlab
"Utilities", struct( ...
    "Visible", true, ...
    "Plot", true, ...
    "Screenshot", true, ...
    "State", "auto")
```

`State="auto"` means enabled when the app has a runtime state that passes the generic serializability check or declares snapshot hooks. If serializability cannot be known cheaply until click time, keep the button enabled and show a clear error.

### Active Plot Selection

Framework needs a concept of "current plot" that does not require app-specific code.

V1 policy:

1. If the workspace has one visible preview axes, use it.
2. If multiple visible axes exist, use the most recently interacted/hovered registered axes.
3. If no active axes is known, show a small framework alert.

Implementation sketch:

- `previewArea` registers every created axes in appdata.
- Pointer motion or button-down events update `labkitUiActiveAxes` without overwriting app callbacks where possible.
- The utility bar asks a private helper for `currentAxes(fig)`.
- Existing context-menu popout still works even if active-axes tracking fails.

This makes the utility bar useful without forcing every app to add local "pop out this plot" buttons.

### Screenshot

Path export:

- Use `exportapp(fig, filename)` for whole-app screenshots because it captures UI components.
- Use `exportgraphics(ax, filename)` for current plot screenshots.

Clipboard:

- Use `copygraphics(ax)` for current plot.
- Whole-app clipboard should be best-effort and may require a temporary image plus platform-specific clipboard integration. Do not promise it until macOS/Windows tests cover it.

### Tests

Add shell tests:

- Utility bar appears by default in a minimal app.
- Utility buttons have stable ids/tags.
- Startup status row still works.
- Hidden GUI mode does not stall.
- Pop-out button targets single visible axes.
- Screenshot-to-path calls `exportapp` through an injectable/testable service.
- Snapshot buttons call save/load service through injected chooser paths in tests.

## API Placement

Recommended public additions:

| Package | API | Reason |
| --- | --- | --- |
| `labkit.ui.tool` | extend `popoutAxes`; keep `enableAxesPopout` | Plot tools operate on axes, not app runtime. |
| `labkit.ui.app` | `saveState`, `loadState` | State belongs to app runtime and definition hooks. |
| `labkit.ui.app` | optional `define(..., "Snapshot", spec)` | App-owned serialization policy must be declared at definition boundary. |
| `labkit.ui.app` | optional `define(..., "Utilities", spec)` | Workbench shell utilities belong to app runtime/shell. |

Recommended private helpers:

```text
+labkit/+ui/+tool/private/extractAxesData.m
+labkit/+ui/+tool/private/writeAxesDataExport.m
+labkit/+ui/+tool/private/generateAxesScript.m
+labkit/+ui/+tool/private/createPopoutToolbar.m
+labkit/+ui/+tool/private/applyAxesStyleCommand.m

+labkit/+ui/+app/private/createUtilityBar.m
+labkit/+ui/+app/private/currentWorkbenchAxes.m
+labkit/+ui/+app/private/createSnapshot.m
+labkit/+ui/+app/private/validateSnapshot.m
+labkit/+ui/+app/private/validateSerializableState.m
+labkit/+ui/+app/private/restoreSnapshot.m
+labkit/+ui/+app/private/exportAppScreenshot.m
```

Do not add a new public `labkit.ui.export` or `labkit.ui.snapshot` facade yet. The surface is not broad enough to justify a new package, and it would increase discovery cost.

## App Impact

Most apps should require no changes for enhanced popout or utility screenshot/plot controls because `previewArea` already enables axes popout.

Apps need changes only when:

- Their state contains handles, listeners, file identifiers, or function handles.
- They want to drop caches before snapshot save.
- They need to rebuild derived state after load.
- They want to opt out of utility bar features.

CSC, FLIR, image-measurement, RHS, and wearable apps should not need local "force redraw" or "export visible plot image" buttons once the plot refresh/viewport policy and utility bar are stable. Domain-specific CSV/MAT result exports remain app-owned.

## Risk Analysis

### Risk: Snapshot Gives False Reproducibility Confidence

Mitigation:

- Name it "state snapshot", not "analysis archive".
- Store same-version metadata and fail on mismatch.
- Do not claim it replaces raw data, scripts, or app-owned exports.

### Risk: Generated Plot Script Is Incomplete

Mitigation:

- Scope script generation to graphics-object reconstruction.
- Include warnings for unsupported children.
- Always write `plot_data.mat` as authoritative data.
- Add tests for common object types.

### Risk: Toolbar Clutter

Mitigation:

- Keep utility bar compact.
- Support app-level opt-out.
- Use framework-owned semantic ids so controls can be rearranged later without changing app code.

### Risk: Clipboard Behavior Differs Across Platforms

Mitigation:

- Use `copygraphics` for axes only.
- Treat whole-app clipboard as optional phase 2.
- Use screenshot-to-path as the reliable first-class feature.

### Risk: State Serialization Becomes App-Specific in Framework

Mitigation:

- Framework validates generic serializable shapes.
- Apps provide hooks for app-specific cleanup and restore.
- No app-specific field names or domains in `+labkit`.

## Implementation Plan

### Phase 1: Enhanced Popout

Files likely touched:

- `+labkit/+ui/+tool/popoutAxes.m`
- `+labkit/+ui/+tool/private/*`
- `tests/cases/gui/labkit_framework/ui/GuiLayoutUiAxesWorkbenchTest.m`
- `docs/ui.md` after implementation is stable

Tasks:

1. Add optional name-value parsing to `popoutAxes`.
2. Factor current copy behavior into private helpers.
3. Add popout toolbar.
4. Add style command helpers.
5. Add data extraction and script generation.
6. Add focused GUI and headless tests.

### Phase 2: Snapshot API

Files likely touched:

- `+labkit/+ui/+app/define.m`
- `+labkit/+ui/+app/run.m`
- new `+labkit/+ui/+app/saveState.m`
- new `+labkit/+ui/+app/loadState.m`
- `+labkit/+ui/+app/private/*Snapshot*.m`
- framework tests under `tests/cases/headless/labkit_framework/ui` and GUI smoke tests
- `docs/ui.md`

Tasks:

1. Add optional `Snapshot` definition field.
2. Add state serializability validator.
3. Add save/load public APIs.
4. Add app hook invocation.
5. Add tests for round-trip, mismatch, and failure atomicity.

### Phase 3: Utility Bar

Files likely touched:

- `+labkit/+ui/+app/private/createTabbedWorkbenchShell.m`
- `+labkit/+ui/+app/private/buildWorkspace.m`
- new `+labkit/+ui/+app/private/createUtilityBar.m`
- active-axes private helpers
- GUI layout tests
- `docs/ui.md`

Tasks:

1. Add shell utility row.
2. Register preview axes.
3. Wire utility actions to popout/copy/save screenshot/save state/load state.
4. Add opt-out/options surface.
5. Update tests for shell row layout and hidden mode.

## Validation Strategy

During development:

- Run the focused UI framework test file after each phase.
- Prefer hidden GUI tests for popout and utility bar behavior.
- Use synthetic line/image axes only; do not track lab sample data.

Before push/merge:

- Run changed-file validation as routed by `docs/testing.md`.
- Run broad non-GUI validation if public APIs or docs changed.
- Manually verify interactive GUI behavior for real clipboard, toolbar feel, and screenshot output because those depend on OS/MATLAB desktop behavior.

## Implementation Acceptance Criteria

The implementation should not be considered complete until these checks are true:

1. Existing app previews still get the axes context menu without app changes.
2. Popout from at least one line plot and one image plot works in hidden GUI tests.
3. Popout style controls edit only the copied figure.
4. Plot image/PDF export uses MATLAB graphics export functions and does not implement a custom renderer.
5. Graphics data export produces a MAT file for all supported object types and a CSV only when the table shape is unambiguous.
6. Generated recreate scripts run without depending on LabKit app packages.
7. `saveState` writes a single `snapshot` variable and never saves runtime handles.
8. `loadState` validates app id, schema, and version before mutating runtime state.
9. Failed snapshot load leaves the previous app state and UI intact.
10. Utility bar commands are discoverable by stable tags or semantic ids in tests.
11. Utility bar can be disabled or partially disabled without editing individual app layouts.
12. Human docs are updated only after public APIs land; this artifact alone is not treated as a released contract.

## First Implementation Slice

The lowest-risk implementation slice is:

1. Enhance `popoutAxes` with a toolbar and copied-figure style controls.
2. Keep all export/script helpers private.
3. Add tests around copied-figure behavior and simple line export.
4. Stop before adding the workbench utility bar.

This slice proves the figure-editing and graphics extraction model without changing the app shell. If that slice is stable, app snapshot can be implemented independently. The utility bar should be last because it depends on both current-axes selection and state/screenshot services.

## Design Decisions

1. Enhanced popout belongs in `labkit.ui.tool`, not app packages.
2. State snapshot belongs in `labkit.ui.app`, not a new facade.
3. Screenshot and utility bar belong in `labkit.ui.app` shell mechanics.
4. Generated script is graph-level reproduction, not workflow replay.
5. Snapshot v1 is strict same-version restore only.
6. No OO conversion is needed for these features.
7. Do not publish data/script extraction APIs until the private schema survives real app usage.

## External Source URLs

- MathWorks `exportgraphics`: https://www.mathworks.com/help/matlab/ref/exportgraphics.html
- MathWorks `copygraphics`: https://www.mathworks.com/help/matlab/ref/copygraphics.html
- MathWorks `exportapp`: https://www.mathworks.com/help/matlab/ref/exportapp.html
- MathWorks `save`: https://www.mathworks.com/help/matlab/ref/save.html
- MathWorks `uitoolbar`: https://www.mathworks.com/help/matlab/ref/uitoolbar.html
- MathWorks `uipushtool`: https://www.mathworks.com/help/matlab/ref/uipushtool.html
- EEGLAB data structures: https://eeglab.org/tutorials/ConceptsGuide/Data_Structures.html
- EEGLAB history scripting: https://eeglab.org/tutorials/11_Scripting/Using_EEGLAB_history.html
- FieldTrip data structures: https://www.fieldtriptoolbox.org/development/datastructure/
- ImageJ macro recorder/utilities: https://imagej.net/ij/docs/guide/146-31.html
- JupyterLab workspaces: https://jupyterlab.readthedocs.io/en/stable/user/workspaces.html
- Matplotlib application interfaces: https://matplotlib.org/stable/users/explain/figure/api_interfaces.html
- Pylustrator documentation: https://pylustrator.readthedocs.io/en/latest/
- napari Viewer API: https://napari.org/stable/api/napari.Viewer.html
