# Runtime And Lifecycle

```labkit-page
id: develop-framework-runtime
type: concept
audience: app-developer
summary: Understand the App-facing runtime contract, lifecycle, state transactions, events, presentation, diagnostics, and cleanup.
```

`labkit.app` is the App-facing runtime contract. Apps declare product meaning; the private runtime owns native MATLAB components, event serialization, transactions, runtime state publication, resources, diagnostics, and cleanup.

## Definition And Launch

Each App-owned `definition.m` is the single immutable product contract, and each entrypoint delegates to it:

```matlab
function varargout = labkit_Example_app(varargin)
[varargout{1:nargout}] = example.definition().launch(varargin{:});
end
```

```matlab
function app = definition()
app = labkit.app.Definition( ...
    Entrypoint="labkit_Example_app", ...
    AppId="examples.example", ...
    Title="Example", ...
    Family="Examples", ...
    AppVersion="1.0.0", ...
    Updated="2026-07-19", ...
    Workbench=example.workbench.buildLayout(), ...
    CreateState=@example.createState, ...
    RefreshState=@example.refreshState, ...
    PresentWorkbench=@example.workbench.present);
end
```

Required Definition arguments are product metadata and one `labkit.app.layout.workbench` value. Optional callbacks are:

| Argument | Signature | Purpose |
| --- | --- | --- |
| `CreateState` | `state = callback(callbackContext,initialInput)` | Create the App-owned scalar runtime state. |
| `Requirements` | `labkit.contract.requirements(...)` | Optionally declare additional facade ranges used by the App. |
| `RefreshState` | `state = callback(state,callbackContext)` | Rebuild App data after a file-list edit. |
| `PresentWorkbench` | `view = callback(applicationState)` | Return the App-owned fragment of the complete visible snapshot. |
| `OnStart` | `applicationState = callback(applicationState,callbackContext)` | Perform a real post-first-commit request or resource initialization. |

Ordinary default state needs no startup callback. Exact syntax and errors are in the generated [public API reference](../../reference/README.md).

`launch("requirements")` and `launch("version")` answer metadata without creating a figure. `launch()` constructs the private native adapter and shows the App.

## Static Workbench Contract

`+workbench/buildLayout.m` returns a tree composed from `labkit.app.layout.*` values. Layout IDs are stable semantic identifiers and must be globally unique.

```matlab
function layout = buildLayout()
controls = { ...
    labkit.app.layout.section("parameters", "Parameters", { ...
        labkit.app.layout.field("gain", ...
            Label="Gain", Kind="numeric", ...
            Bind="project.parameters.gain"), ...
        labkit.app.layout.button("exportResult", ...
            "Export", @example.resultFiles.exportResult, ...
            Tooltip="Export the current analyzed result.")})};
workspace = labkit.app.layout.workspace( ...
    labkit.app.layout.plotArea( ...
        "previewPlot", @example.previewPlot.draw));
layout = labkit.app.layout.workbench( ...
    controls, Workspace=workspace);
end
```

Layout controls own direct callbacks. Plot areas own direct renderers. There is no handler, renderer, command, or capability registry for Apps to maintain. Definition compiles the immutable graph once and validates callback roles, renderer roles, IDs, bindings, and view capabilities before UI mutation.

Complex Apps keep the top-level workbench readable by composing capability-owned `layoutSection`, `workspaceTable`, or `workspacePlot` functions in user order.

## Validation

Use focused contract tests for Definition, layout, callbacks, snapshots, state invariants, and runtime transactions. Add downstream App tests for changed behavior and a bounded hidden-GUI test for native wiring. Automated hidden GUI tests do not prove dialog quality, pointer feel, scientific validity, or a complete interactive workflow.

See [Testing](../testing.md) and [Build A Complete App](../app-authoring/complete-app.md).

## State And Transactions

Runtime treats App state as one opaque scalar struct. An App may organize that value into convenient buckets, for example:

```matlab
applicationState.project
applicationState.session
```

Those names have no framework durability semantics. A callback receives the previous complete state and returns a candidate complete state. The runtime:

1. serializes the event;
2. invokes the direct callback;
3. verifies that candidate state remains one scalar struct;
4. builds and validates the complete view snapshot;
5. reconciles native components;
6. publishes state and view together.

Failure rolls back both state and presentation. Apps do not implement busy flags, callback queues, readiness timers, or figure close guards.

The runtime has no project schema, document identity, dirty flag, recovery file, save command, or restore command. Apps that need continuation own that workflow and archive format explicitly. Runtime diagnostics may capture state for debugging, but diagnostic capture is not a task-save contract.

Runtime enters its non-reentrant busy state before invoking an ordinary action callback. New button, field, table, file-list, workspace, and managed-interaction input is ignored until that transaction finishes. Visible feedback is delayed briefly: short callbacks therefore leave the pointer, title, and enabled appearance untouched, while longer callbacks show the action's `BusyMessage` (or its button label), switch to the busy pointer, and freeze mutable controls. The committed Snapshot restores the final enabled state. User-facing log messages emitted while that feedback is visible replace the current stage text, so an App can report real named stages through its existing diagnostic timeline without owning a second progress window.

Slider and paired-spinner input uses a stricter direct-manipulation boundary. Intermediate slider drag values update the native slider/spinner display only; they do not enter Runtime, mutate App state, call `PresentWorkbench`, or write diagnostics. Pointer release commits the final value once. Rapid spinner changes are trailing-edge coalesced and commit the latest value after a one-second quiet interval. A final value equal to the committed value does nothing. These commits deliberately suppress visible busy feedback to avoid flicker, so their callback may only normalize and bind state, update light derived state, invalidate stale results, or perform one bounded preview or automatic refresh. It must not perform unbounded or potentially long IO/calculation, export, wait, poll, pause, or log each adjustment. A navigation control may perform one bounded current-record or current-window preview read when that read is the interaction's core purpose. Put work that cannot meet an interactive response budget behind an explicit **Run**, **Generate**, **Import**, or **Export** action, where delayed busy feedback and bounded progress are meaningful.

Refresh ownership follows the changed meaning. A pure binding with no derived effect needs no callback. A display-only option may rebuild its bounded current preview after commit. A scientific parameter may automatically refresh once after commit when that work is bounded; otherwise it invalidates prior results and waits for an explicit Run action. Source-list edits use `RefreshState`; ordinary presentation never polls files or devices. Stream producers use `postEvent`, whose pending IDs are latest-wins, and the surviving state update presents once.

Use direct dotted `Bind` paths for ordinary fields, ranges, sliders, file sources, and selection. The roots and nesting are App-owned. Bound controls need no callback or presenter operation unless the App has additional derived meaning.

## Source Lists And State Refresh

`labkit.app.layout.fileList` owns file/folder selection, live source records, removal, clearing, and optional selection binding:

```matlab
labkit.app.layout.fileList("sources", ...
    Filters=["*.csv", "CSV files"], ...
    Bind="project.inputs.sources", ...
    SelectionBind="session.selection.sources", ...
    SourceRole="measurement", ...
    SourceIdPrefix="source")
```

The App does not mirror those UI lifecycle actions with callbacks. Runtime updates the bound source records and invokes `RefreshState` after source changes:

```matlab
function state = refreshState(state, callbackContext)
paths = labkit.app.source.paths(state.project.inputs.sources);
state.session.measurements = example.sourceFiles.read(paths);
end
```

Source records are runtime UI values with IDs, roles, and direct paths. Read paths at IO boundaries. If an App writes an archive, that App decides how paths are represented and relocated; the framework does not rebase or relink them.

## Typed Events

Callbacks are attached only where an App owns real behavior:

- button: `state = callback(state,callbackContext)`
- field, range, slider, workspace page, or interaction change: `state = callback(state,value,callbackContext)`
- table edit: `state = callback(state,labkit.app.event.TableCellEdit,callbackContext)`
- table selection: `state = callback(state,labkit.app.event.TableCellSelection,callbackContext)`

Name the boundary values explicitly and delegate domain work through narrow inputs:

```matlab
function applicationState = replaceGroupValue( ...
        applicationState, cellEdit, callbackContext)
arguments
    applicationState (1,1) struct
    cellEdit (1,1) labkit.app.event.TableCellEdit
    callbackContext (1,1) labkit.app.CallbackContext
end

groups = applicationState.project.groups;
applicationState.project.groups = ...
    example.groupData.replaceValue(groups, ...
        cellEdit.Row, cellEdit.Column, cellEdit.NewValue);
end
```

Do not pass the complete state or callback context into calculation code that only needs groups and one edited value.

## Posted Stream Events

Timers and asynchronous serial, TCP, UDP, or other streaming callbacks cannot mutate App state or native controls directly. A device callback must drain already-available input and return; it must not wait, poll, draw, or perform per-sample presentation on MATLAB's shared event thread. The producer writes to its own buffer and publishes one semantic state update through the callback context:

```matlab
function onSample(buffer, callbackContext)
buffer.append(readOneSample());
callbackContext.postEvent("stream.live.refresh", @refreshLiveState);
end

function state = refreshLiveState(state, callbackContext)
buffer = callbackContext.getResource("sampleBuffer");
state.session.live = buffer.visibleSnapshot();
end
```

`postEvent` accepts a fixed `state = update(state,callbackContext)` callback. Pending posts with the same event ID are latest-wins coalesced, so a fast producer cannot build an unbounded UI refresh queue. Runtime executes the surviving update through the ordinary serialized validation, presentation, diagnostics, commit, and rollback path. Posts after Runtime close are ignored. Posted updates do not enter the user-action busy lifecycle: they neither set a watch pointer nor disable controls while a live stream is presenting. An update failure rolls back that posted transaction and is recorded without failing the producer callback that submitted it, including when the post was queued while another App transaction was still completing. A queued post does not execute inside that active transaction; it remains coalesced until the transaction and its native presentation have completed, preventing a fast producer from starving the initiating control callback. Protocol parsing, buffering, retry policy, sampling, and reconnect behavior remain App-local or belong to the relevant driver facade.

## Complete View Snapshots

Runtime starts from layout defaults, bindings, file state, log text, and status text. `PresentWorkbench` returns only derived App-owned operations:

```matlab
function view = present(applicationState)
view = labkit.app.view.Snapshot();
view = view.include(example.previewPlot.present( ...
    applicationState.session.measurements, ...
    applicationState.project.parameters));
view = view.enabled("exportResult", ...
    ~isempty(applicationState.session.measurements));
end
```

The combined snapshot must cover every semantic target exactly as its layout capabilities require. `Snapshot.include` composes feature-owned fragments without opening a generic property-patch schema.

The native adapter compares each complete snapshot operation with the last committed operation and applies only changed values. An unchanged plot model, table, choice list, enabled state, or text value therefore performs no native write. Complete snapshots remain the atomic authoring contract; Apps do not construct patches themselves.

Plot presentation passes a prepared model to the renderer declared by its plot area:

```matlab
view = view.renderPlot("previewPlot", model);
```

```matlab
function draw(axesById, model)
ax = axesById.main;
cla(ax);
plot(ax, model.x, model.y);
end
```

Renderers own drawing and viewport policy, not workflow decisions or project mutation. Display-only graphics disable hit testing. Managed interaction specs own editable gestures and their private native resources.

For a multi-row plot dashboard, place multiple plot areas in one workspace page. Page content is arranged vertically, while each plot area independently chooses `single`, horizontal `pair`, or vertical `stack`. Two paired plot areas therefore form a 2-by-2 dashboard without App-owned native containers. `ColumnWidths={'1x', 90}` gives a pair a flexible main plot and a fixed-width scale or histogram. Stacked axes share the available height equally.

```matlab
top = labkit.app.layout.plotArea("topPlots", @drawTop, ...
    Layout="pair", AxisIds=["image" "profile"]);
bottom = labkit.app.layout.plotArea("bottomPlots", @drawBottom, ...
    Layout="pair", AxisIds=["result" "scale"], ...
    ColumnWidths={'1x', 90});
workspace = labkit.app.layout.workspace(Title="Plots");
workspace = workspace.page("plots", "Plots", {top, bottom});
workspace = workspace.initialPage("plots");
```

Declare managed gestures statically on their plot area and provide their current value in the snapshot:

```matlab
crop = labkit.app.interaction.rectangle( ...
    "cropRegion", @example.cropGeometry.moveCrop);
plot = labkit.app.layout.plotArea( ...
    "previewPlot", @example.previewPlot.draw, Interactions={crop});
```

```matlab
view = view.rectangle( ...
    "cropRegion", project.annotations.crop, ImageSize=size(image));
```

Named contracts also cover anchor paths, paired anchors, fixed point slots, transient region selection, intervals, and scale references. Apps never author `Kind`, `Targets`, `Event`, or `Options` transport structs.

Renderer mechanics such as complete clears, empty-state messages, fitting, fixed-aspect canvases, and axes-relative annotation placement live under `labkit.app.plot.*`. Apps own when those operations occur, user wording, and whether a semantic change should preserve or fit the viewport.

## CallbackContext

`labkit.app.CallbackContext` is sealed and exposes specifically named runtime operations for dialogs, status and diagnostics, runtime sources, render surfaces, and managed resources. It does not expose figures, component registries, queues, lifecycle handles, or a nested service bag.

`postEvent` is the single generic boundary for timer-, serial-, network-, and monitor-driven refresh. The producer owns protocol and buffering; Runtime owns coalescing, serialization, validation, presentation, rollback, diagnostics, and close behavior.

Use `callbackContext.inform(message,title)` for successful or neutral information; it presents the native information icon. Reserve `callbackContext.alert(message,title)` for a blocking problem; it presents the native error icon. Keeping these operations distinct prevents completed INFO outcomes from inheriting failure styling.

Use context methods only at a callback or reconstruction boundary. Pure readers, calculations, result builders, and render-model builders accept ordinary explicit values.

`callbackContext.chooseOption(prompt, choices, ...)` owns ordinary native confirmation choices. `Title` controls the dialog title, `DefaultChoice` selects the Enter-key action, and `CancelChoice` is returned when the user dismisses the dialog. All three named choices must be members of the declared nonempty unique choice row. File and folder methods remain separate because they return paths and use platform file choosers. Successful input and output choices are remembered separately across App windows. A valid App-supplied start path takes precedence; cancellation or an invalid path does not replace the last successful folder.

The framework has no generic task-document writer or reader. An App that truly needs continuation owns the file chooser, archive format, source lookup, compatibility policy, and reconstruction callback. Returning the reconstructed application state from that ordinary callback still uses Runtime's normal validation, presentation, and rollback transaction. Archive files capture one current/final snapshot; diagnostic state exports remain a separate debugging facility.

## App-Owned Results And Continuation

Apps write final result files directly. Crop-like workflows may read their final manifest to reconstruct a task; an editor such as Video Marker may work directly in an App-owned MAT archive. Other Apps do not gain save/open behavior merely because they have structured runtime state.

An App with continuation owns its buttons, format, current-version validation, path policy, and resume meaning. The runtime supplies no envelope, migration loop, atomic-save policy, project menu, or generic result manifest.

Resources use App-owned IDs. Replacing the same ID is idempotent; Apps remove resources when a workflow no longer needs them, and the runtime cleans every surviving resource on close.

## Diagnostics And Session Logging

Every ordinary App launch starts one sanitized session event stream and durable journal. Launch arguments do not select a debug mode, change startup behavior, or generate sample data. Runtime records one root operation around a semantic user action, a presentation-start checkpoint when the action has an App callback, a terminal result, and nested dialog, source, resource, result, or failure boundaries when they occur. It does not record separate state-updated, state-validated, presentation-committed, or rollback-cleanup breadcrumbs for every callback.

App callbacks add domain events through `callbackContext.log(severity,eventName,message,Name=Value)`. Use `trace` only for explicitly enabled forensic detail, `debug` for bounded maintainer progress or branch facts, `info` for a meaningful user-visible milestone or completed action, `warning` for an unexpected recoverable condition that requires attention, `error` for a failed requested operation, and `critical` only when the session cannot safely continue. A control value changing, selection moving, preview repainting, loop iteration, successful validation, or normal state assignment is not an INFO event. Long work may report a named DEBUG progress stage at start, completion, and no more often than the owning progress heartbeat requires; never log each item or sample.

Messages are at most 512 characters and must not contain absolute paths or original filenames. Attributes are a bounded scalar summary: controlled semantic text (`enum`, `unit`, `reason`, `runtimeAlias`, or framework `sourceAlias`), finite scalar counts/indices/ordinals/durations, and a small `dimensions` shape. Paths, filenames, subject/device/user identity, scientific values or arrays, arbitrary nested values, and free text are rejected before the event reaches memory or disk. Pass a caught `MException` through `Exception`; Runtime retains a bounded identifier, sanitized message, and function names with line numbers, never source-file paths.

The App's **Tools > Diagnostics** menu opens the live viewer for the current session. Each viewer title names the App that owns the session. Its only filter selects the minimum visible severity from TRACE, DEBUG, INFO, WARNING, ERROR, or CRITICAL. TRACE is the default view threshold, but it does not manufacture detail that was not captured. Selecting a row shows the complete structured record, including correlation IDs, attributes, terminal disposition, and any retained exception details.

Runtime initially captures DEBUG and higher records to bound ordinary-session cost. The viewer provides an explicit **Enable TRACE** / **Disable TRACE** control when detailed capture is needed; errors do not change that setting. DEBUG retains semantic operation starts, the App-callback presentation checkpoint, terminal boundaries, bounded maintainer progress, and failures. TRACE adds successful App/runtime presentation stages only while explicitly enabled. Enabling TRACE never reconstructs earlier detail. The live stream and viewer projection are each bounded by both record count and serialized bytes; the native table batches updates at up to 10 Hz.

The durable journal is the sole retained diagnostic and usage-history artifact. New sessions live at `artifacts/logs/sessions/session-<app-id>-<UTC-start>-<unique-suffix>/`. `manifest.json` records the App ID and version, LabKit App SDK version, MATLAB release, session lifecycle timestamps and state, retained segment counts, and degradation counters. Ordered canonical events remain in `events-*.jsonl`. Low-level identical records may coalesce within the documented window; WARNING and higher records and terminal results remain exact. Buffer, segment, per-session, and journal-root limits prevent unbounded growth; root retention removes only older closed sessions and never the current or another active session.

Root-operation starts and App-presentation starts are durable breadcrumbs. Durability closes and reopens the active segment but does not atomically rewrite the manifest at each breadcrumb. The manifest updates on buffered flush, retention change, degradation, and orderly close. Journal health emits one degradation transition and one bounded dropped-record summary; later unavailable writes advance counters without recursively generating one warning per lost record.

Journal degradation remains visible in the surviving in-memory stream; logging failures never alter callback transaction semantics or scientific results. A callback exception is recorded as an ERROR with `failed` operation result, rollback disposition, safe exception identifier, and sanitized function stack.

Runtime close is also an instrumented lifecycle operation. Resource and native adapter cleanup continue independently; a cleanup exception is retained and persisted before the journal closes, then returned to the caller. Diagnostics cannot manufacture evidence for a native gesture that never committed, an event rejected by the payload policy, or an exception swallowed by App code without logging. A MATLAB hang or abnormal termination leaves the last durable unterminated semantic boundary without preserving every transient adjustment.
