# LabKit App SDK

```labkit-page
id: develop-framework
type: task
audience: app-developer
summary: Understand the labkit.app lifecycle, layout, transactions, execution, source lists, diagnostics, and other domain-neutral App SDK responsibilities.
```

`labkit.app` is the MATLAB App SDK above LabKit's GUI-free domain libraries. Apps own scientific workflow, calculations, units, wording, plots, and exports. The SDK owns semantic layout, transactions, execution queues, lifecycle, runtime source lists, diagnostics, dialogs, resources, and native components.

## Start Here

| Goal | Documentation |
| --- | --- |
| Build or refactor an App | [Build a Complete App](../app-authoring/complete-app.md) |
| Understand ownership boundaries | [Architecture](../app-authoring/architecture.md) |
| Declare compatible LabKit modules | [Compatibility contracts](compatibility/contracts.md) |
| Look up exact MATLAB syntax | [Public API reference](../../reference/README.md) |
| Browse the App SDK API by capability | [App SDK API](app-sdk-api.md) |
| Validate framework or GUI changes | [Testing](../testing.md) |

## SDK Map

The required path has three concepts:

| API | Purpose |
| --- | --- |
| `labkit.app.Definition` | App identity, lifecycle callbacks, layout, and launch |
| `labkit.app.layout.*` | Semantic inputs, displays, containers, and workbench structure |
| `labkit.app.view.Snapshot` | Derived visible state and App-owned rendering |

Read an App in this order: `definition.m` shows its complete contract, `+workbench/buildLayout.m` shows the user workflow, and its capability packages show the controls, state transitions, presentation, and rendering owned by each feature. App-specific state construction and reconstruction stay inside that App.

Layout controls bind directly to named App callbacks, and plot areas bind directly to their renderer. Apps do not maintain handler, renderer, or capability registries. Runtime-injected values are `labkit.app.CallbackContext` and typed `labkit.app.event.*` payloads. Callbacks name those boundary values explicitly and delegate domain work through narrow inputs.

Optional capabilities are grouped by purpose:

| Package | Purpose |
| --- | --- |
| `labkit.app.event.*` | Typed callback payloads |
| `labkit.app.interaction.*` | Managed plot gestures with direct callbacks |
| `labkit.app.plot.*` | Domain-neutral axes redraw, message, fit, and annotation mechanics |
| `labkit.app.source.*` | Live file-list source values |
| `labkit.app.dialog.*` | Explicit dialog outcomes |
| `labkit.app.CallbackContext` | Runtime operations available inside callbacks |

## Smallest App

```matlab
function app = definition()
    workbench = labkit.app.layout.workbench({ ...
        labkit.app.layout.field("gain", Label="Gain", ...
            Kind="numeric", Bind="project.parameters.gain"), ...
        labkit.app.layout.button("run", "Run", @runAnalysis, ...
            Tooltip="Compute the result from the current gain.")});
    app = labkit.app.Definition( ...
        Entrypoint="labkit_Example_app", AppId="example", ...
        Title="Example", Family="Examples", ...
        AppVersion="1.0.0", Updated="2026-07-19", ...
        Workbench=workbench);
end
```

The entrypoint calls `definition().launch(...)`. Definition compiles the immutable semantic graph, validates direct callback and renderer signatures, and checks every declared LabKit facade version before creating a figure and building one private native platform plan.

## Paved Road

- Bind controls to dotted paths in the App's own in-memory state. The SDK does not reserve root field names or define a project/session schema.
- Keep ordinary actions on the framework's consistent single-line native button rhythm. A readonly `field` renders as compact, selectable text inside a fully inset native border; it automatically wraps and adjusts to the available width. Apps do not declare line counts or a separate message type. Dividers belong between resizable sections, not after the final section.
- Give every editable semantic surface one declared behavior owner before launch: editable fields, ranges, and sliders use `Bind` or `OnValueChanged`; file lists require `Bind`; plot view modes require `OnValueChanged`; and editable table columns require `OnCellEdited`. Workspace page callbacks require named pages. Binding and callback changes use the same validation and rollback behavior.
- Use `labkit.app.layout.fileList` for live file records and selection. Multi-file collections use native multi-selection; a semantic single-file slot declares `MaxFiles=1` and single selection. Its compact path surface wraps the complete filename in selectable text and exposes the complete absolute path as hover text. File buttons describe only files because folder and recursive-tree acquisition have separate controls. Set `AllowDuplicatePaths=true` only when separate workflow tasks may share one resolved path, and present row-level workflow state with `Snapshot.fileItemStatuses`. For content formats that cannot be distinguished by filename extension, declare a pure batch `PathFilter` and a reader-facing `PathFilterDescription`. The runtime applies the predicate only to newly proposed files, omits rejected paths before source records are created, and reports aggregate kept/filtered counts without exposing filenames. Unhandled validation or parsing failures from file-panel actions roll back transactionally and appear in an alert rather than only in callback output. Source changes invoke the App's optional state refresh; Apps do not mirror choose, remove, clear, or selection UI events.
- Give every scientific or workflow action an App-owned `Tooltip`. The framework guarantees a nonempty label-based fallback, while repository guardrails require tracked Apps to explain the action instead of repeating its visible label. Auxiliary file-list buttons derive hover text from their visible labels.
- Give a potentially long action a concise App-owned `BusyMessage`. Runtime rejects reentrant action input as soon as the action starts, but delays visible busy feedback briefly so quick actions do not flash the pointer, title, or disabled controls. If work outlives that delay, Runtime freezes mutable leaf inputs while leaving tabs, panels, plots, and the last committed view visible until the next view is ready. Slider drag stays native-local until release; rapid paired-spinner edits latest-wins coalesce before one commit. These direct-manipulation commits do not show action-style busy feedback and therefore remain free of unbounded or potentially long IO/calculation, export, waiting, and per-adjustment logs. They may perform one bounded current preview or automatic refresh; a navigation control may perform one bounded current-record or current-window preview read. User-facing `info`, `warning`, or failure logs emitted during an explicit action update the visible stage; Apps do not create progress windows.
- Rebuild transient data in `RefreshState` and read source paths with `labkit.app.source.paths`.
- Use `context.postEvent(eventId,updateState)` when a timer, device driver, network stream, monitor, or dashboard needs to publish fresh App state. Runtime coalesces pending posts with the same semantic ID, runs the latest update as a normal validated transaction after any active transaction has completed, and ignores posts after close. Posted stream refreshes do not activate the user-action busy pointer or disable controls.
- Return only derived view state from `labkit.app.view.Snapshot`; runtime supplies layout defaults, bindings, file state, log text, and status text. Use `Snapshot.text` on a slider when a selector changes that slider's parameter meaning or unit; the operation updates the visible label without changing the numeric value.
- Give short `statusPanel` summaries an explicit `Lines` hint so the native layout reserves detail height only for genuinely multiline content.
- Use `labkit.app.layout.dataTable` with `labkit.app.event.TableCellEdit` and `labkit.app.event.TableCellSelection`; Apps never decode native events.
- Use `labkit.app.layout.plotArea` and a fixed `renderer(axesById,model)` callback. `axesById` is always a named struct, even when the plot area declares only one axis.
- Pass a transient `ViewRevision` to `Snapshot.renderPlot` for every plot whose data domain can change. The adapter preserves user zoom while the revision is unchanged and accepts renderer-fitted limits once when it changes. Change the revision for a new source/result, selected coordinate or unit/scale transformation, analysis result that changes the plotted domain, or an explicit fit/reset action. Keep it unchanged for line, marker, palette, grid, legend, annotation-visibility, and other display-only changes. Image plots also change it when image identity, dimensions, orientation, or crop changes, but not for same-size frame navigation or overlay editing. Live plots use an App-owned rolling/out-of-view policy rather than changing the revision for every sample. Semantic text revisions may contain App-owned IDs and choices, never source paths.
- Pass one workspace node or a row cell array of vertically arranged nodes to `workspace.page`; growable tables and plots share the available page height without an App-authored wrapper section.
- Use `layout.group(..., Title="...")` for a nested reader-facing control boundary inside a section; leave `Title` blank for arrangement-only groups.
- A control tab containing one growable file list, table, log, status, or plot surface fills the available tab height. Tabs with longer mixed content remain scrollable.
- Declare editable overlays with `labkit.app.interaction.*` on the plot area; supply their current values with same-named Snapshot methods.
- Open `anchorPath` editors order a new point by the nearest location on the visible path: points beyond the start prepend, points beyond the end append, and interior points insert into the owning curve segment. Zoom does not change that ordering decision.
- For a managed rectangle with `OnBackgroundPressed`, an un-dragged click anywhere on its plot—including inside the rectangle—uses that point callback; dragging the rectangle still uses its change callback.
- A `pointSlots` editor distinguishes gestures by their starting location: drag a point or its supplied hit region to move it, drag empty plot space to marquee-select several points, and drag any selected point to move the selected group. Use `OnSelectionChanged` to store selected indices and `OnBackgroundPressed` for a plain empty-space click such as placing copied items.
- Use `labkit.app.plot.clearAxes`, `showMessage`, and `fitAxesToGraphics` for renderer mechanics; `EqualDataUnits=true` makes a one-time fitted equal-scale view from the settled native axes allocation without dispatching pending UI callbacks, without changing the allocation or locking later zoom. Apps still decide message wording and viewport policy.
- Write App result files directly through the App-owned export capability. Any manifest or task archive is an App contract, not an SDK object.

Runtime validates candidate state and the complete view snapshot before publishing either. The private MATLAB adapter maps semantic IDs to native components, skips unchanged native property writes, reuses direct associations between controls and their labels, preserves plot viewports, normalizes native event differences, and never exposes component registries to Apps. If a native property rejects an otherwise validated operation, the causal diagnostic identifies both the semantic target and operation kind before preserving the original MATLAB error.

Normal App launches show the completed native window. Official GUI validation uses the same launch path with a framework-owned visibility policy: `hidden` keeps the final window off screen and `minimized` minimizes it after startup. Tests therefore exercise real controls without individual Apps or test methods having to hide the window after launch.

## Built-in App Tools

The native runtime installs one top-level **Tools** menu so framework-owned utilities do not compete with the App's workflow controls:

- **Copy Main Plots** copies the active workspace page as one image, retaining its plot arrangement, current viewports, legends, colorbars, and both Y axes. Nested tabs contribute only their selected page. An empty workspace reports that no plots are available.
- **Copy Current Interface** copies the current App window, including controls and the selected tabs, as one image. It captures the interface through MATLAB `exportapp`; it does not attempt to treat UI containers as plotting axes.
- **Diagnostics** opens the App-named Session Log for the current launch. Its only filter selects the minimum visible severity. Manual TRACE capture adds detailed presentation stages from that point forward; it never starts automatically after an error.

Right-click a plot for **Copy this plot**, **Send this plot to Studio**, or **Open axes in new figure**. **Copy selected plots...** offers an explicit selection across workspace pages and assembles those plots in a grid without changing the selected tabs. Editable standalone popouts support one Y axis; dual-Y plots direct users to image copying or Studio so the right ruler is not silently lost. These clipboard actions produce raster images; use the owning App's result exports for numeric data and Figure Studio for editable figures. Hidden tabs may contain plots that the App has not computed yet, so inspect the selected plots before reporting them.

**Plot diagnostics > Profile Studio handoff** repeats the selected plot transfer with the MATLAB profiler and writes the existing profiling tool's report. Ordinary transfers already record discovery, launch, native construction, initial state, and first presentation durations in the source and destination session journals; select Debug in the Session Log to inspect timing records. The source action shows a busy pointer and rejects duplicate transfer clicks until it finishes. Profiling adds overhead and should be used to locate costs, while ordinary repeated transfers measure user latency. MATLAB still performs UI construction on its client event loop.

Clipboard access and complete-interface capture require a graphics-enabled local MATLAB session. Some batch configurations, including R2022b, reject these native operations even when hidden App controls can be constructed. The operation failure remains in the Session Log; use a display-enabled MATLAB session for copying. This does not change App-owned numeric or figure file exports.

The SDK has no task archive, save/load callbacks, dirty tracking, recovery files, or generic continuation workflow. Apps that genuinely support pausing and continuing work own explicit controls and their complete JSON, CSV, or MAT snapshot format.

Each App session keeps its persistent structured journal beneath `artifacts/logs/sessions/` in the active LabKit installation. New folder names include the App ID, UTC start time, and a unique suffix. `manifest.json` identifies the App and framework versions, MATLAB release, lifecycle state, timestamps, retained segments, and degradation counters; `events-*.jsonl` contains the canonical correlated event records. These files are the direct diagnostic and usage-history interface for maintainers and analysis agents; there is no separate diagnostic ZIP or App-state snapshot. LabKit does not automatically migrate or delete journals from this folder; users can inspect, archive, or remove generated artifacts with ordinary filesystem tools. Releases that previously wrote session journals beneath MATLAB's `prefdir/LabKit/logs/` leave those existing files unchanged. The journal subsystem does not inspect or prune other sessions in the background.

Before Runtime enters an App callback it durably closes and reopens the active journal segment after writing the root operation start. State-update and validation stages stay in the buffered event stream; immediately before native presentation, Runtime writes those stages plus a durable presentation-entry checkpoint. If MATLAB hangs, the newest operation without a terminal event identifies the last entered stage on the next launch.

These actions are framework-owned native behavior. Apps do not declare menu items or implement clipboard or session-log integration.

App callbacks use `CallbackContext.inform` for successful or neutral information and reserve `CallbackContext.alert` for blocking problems. The two capabilities map explicitly to native information and error icons.

Framework concepts and source names are versionless. Compatibility belongs to `labkit.app.version`; any task-archive version belongs to the App that defines that archive. Runtime has no project document identity or dirty state.

## Related Topics

- [App catalog](../../use/apps/README.md)
- [App development](../app-authoring/app-development.md)
- [Changes](../../changes/README.md)
