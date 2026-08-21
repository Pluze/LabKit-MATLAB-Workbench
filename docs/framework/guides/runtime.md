# Runtime And Lifecycle

`labkit.app` is the App-facing runtime contract. Apps declare product meaning;
the private runtime owns native MATLAB components, event serialization,
transactions, runtime state publication, resources, diagnostics, and cleanup.

## Definition And Launch

Each App-owned `definition.m` is the single immutable product contract, and
each entrypoint delegates to it:

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

Required Definition arguments are product metadata and one
`labkit.app.layout.workbench` value. Optional callbacks are:

| Argument | Signature | Purpose |
| --- | --- | --- |
| `CreateState` | `state = callback(callbackContext,initialInput)` | Create the App-owned scalar runtime state. |
| `Requirements` | `labkit.contract.requirements(...)` | Optionally declare additional facade ranges used by the App. |
| `RefreshState` | `state = callback(state,callbackContext)` | Rebuild App data after a file-list edit. |
| `PresentWorkbench` | `view = callback(applicationState)` | Return the App-owned fragment of the complete visible snapshot. |
| `OnStart` | `applicationState = callback(applicationState,callbackContext)` | Perform a real post-first-commit request or resource initialization. |
| `BuildSyntheticSample` | `sample = callback(callbackContext)` | Build clean-room debug input when the App supports it. |

Ordinary default state needs no startup callback. Exact syntax and errors are
in the generated [public API reference](../../reference/README.md).

`launch("requirements")` and `launch("version")` answer metadata without
creating a figure. `launch()` constructs the private native adapter and shows
the App.

## Static Workbench Contract

`+workbench/buildLayout.m` returns a tree composed from
`labkit.app.layout.*` values. Layout IDs are stable semantic identifiers and
must be globally unique.

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

Layout controls own direct callbacks. Plot areas own direct renderers. There
is no handler, renderer, command, or capability registry for Apps to maintain.
Definition compiles the immutable graph once and validates callback roles,
renderer roles, IDs, bindings, and view capabilities before UI mutation.

Complex Apps keep the top-level workbench readable by composing
capability-owned `layoutSection`, `workspaceTable`, or `workspacePlot`
functions in user order.

## State And Transactions

Runtime treats App state as one opaque scalar struct. An App may organize that
value into convenient buckets, for example:

```matlab
applicationState.project
applicationState.session
```

Those names have no framework durability semantics. A callback receives the
previous complete state and returns a candidate complete state. The runtime:

1. serializes the event;
2. invokes the direct callback;
3. verifies that candidate state remains one scalar struct;
4. builds and validates the complete view snapshot;
5. reconciles native components;
6. publishes state and view together.

Failure rolls back both state and presentation. Apps do not implement busy flags, callback queues, readiness
timers, or figure close guards.

The runtime has no project schema, document identity, dirty flag, recovery
file, save command, or restore command. Apps that need continuation own that
workflow and archive format explicitly. Runtime diagnostics may capture state
for debugging, but diagnostic capture is not a task-save contract.

Runtime enters its non-reentrant busy state before invoking a callback. New
button, field, table, file-list, workspace, and managed-interaction input is
ignored until that transaction finishes. Visible feedback is delayed briefly:
short callbacks therefore leave the pointer, title, and enabled appearance
untouched, while longer callbacks show the action's `BusyMessage` (or its
button label), switch to the busy pointer, and freeze mutable controls. The
committed Snapshot restores the final enabled state. User-facing log messages
emitted while that feedback is visible replace the current stage text, so an
App can report real named stages through its existing diagnostic timeline
without owning a second progress window.

Use direct dotted `Bind` paths for ordinary fields, ranges, sliders, file
sources, and selection. The roots and nesting are App-owned. Bound controls need no
callback or presenter operation unless the App has additional derived meaning.

## Source Lists And State Refresh

`labkit.app.layout.fileList` owns file/folder selection, live source records,
removal, clearing, and optional selection binding:

```matlab
labkit.app.layout.fileList("sources", ...
    Filters=["*.csv", "CSV files"], ...
    Bind="project.inputs.sources", ...
    SelectionBind="session.selection.sources", ...
    SourceRole="measurement", ...
    SourceIdPrefix="source")
```

The App does not mirror those UI lifecycle actions with callbacks. Runtime
updates the bound source records and invokes `RefreshState` after source
changes:

```matlab
function state = refreshState(state, callbackContext)
paths = labkit.app.source.paths(state.project.inputs.sources);
state.session.measurements = example.sourceFiles.read(paths);
end
```

Source records are runtime UI values with IDs, roles, and direct paths. Read
paths at IO boundaries. If an App writes an archive,
that App decides how paths are represented and relocated; the framework does
not rebase or relink them.

## Typed Events

Callbacks are attached only where an App owns real behavior:

- button: `state = callback(state,callbackContext)`
- field, range, slider, workspace page, or interaction change:
  `state = callback(state,value,callbackContext)`
- table edit:
  `state = callback(state,labkit.app.event.TableCellEdit,callbackContext)`
- table selection:
  `state = callback(state,labkit.app.event.TableCellSelection,callbackContext)`

Name the boundary values explicitly and delegate domain work through narrow
inputs:

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

Do not pass the complete state or callback context into calculation code that
only needs groups and one edited value.

## Posted Stream Events

Timers and asynchronous serial, TCP, UDP, or other streaming callbacks cannot
mutate App state or native controls directly. A device callback must drain
already-available input and return; it must not wait, poll, draw, or perform
per-sample presentation on MATLAB's shared event thread. The producer writes
to its own buffer and publishes one semantic state update through the callback
context:

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

`postEvent` accepts a fixed `state = update(state,callbackContext)` callback.
Pending posts with the same event ID are latest-wins coalesced, so a fast
producer cannot build an unbounded UI refresh queue. Runtime executes the
surviving update through the ordinary serialized validation, presentation,
diagnostics, commit, and rollback path. Posts after Runtime close are ignored.
Posted updates do not enter the user-action busy lifecycle: they neither set a
watch pointer nor disable controls while a live stream is presenting.
An update failure rolls back that posted transaction and is recorded without
failing the producer callback that submitted it, including when the post was
queued while another App transaction was still completing. A queued post does
not execute inside that active transaction; it remains coalesced until the
transaction and its native presentation have completed, preventing a fast
producer from starving the initiating control callback.
Protocol parsing, buffering, retry policy, sampling, and reconnect behavior
remain App-local or belong to the relevant driver facade.

## Complete View Snapshots

Runtime starts from layout defaults, bindings, file state, log text, and
status text. `PresentWorkbench` returns only derived App-owned operations:

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

The combined snapshot must cover every semantic target exactly as its layout
capabilities require. `Snapshot.include` composes feature-owned fragments
without opening a generic property-patch schema.

The native adapter compares each complete snapshot operation with the last
committed operation and applies only changed values. An unchanged plot model,
table, choice list, enabled state, or text value therefore performs no native
write. Complete snapshots remain the atomic authoring contract; Apps do not
construct patches themselves.

Plot presentation passes a prepared model to the renderer declared by its
plot area:

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

Renderers own drawing and viewport policy, not workflow decisions or project
mutation. Display-only graphics disable hit testing. Managed interaction
specs own editable gestures and their private native resources.

For a multi-row plot dashboard, place multiple plot areas in one workspace
page. Page content is arranged vertically, while each plot area independently
chooses `single`, horizontal `pair`, or vertical `stack`. Two paired plot areas
therefore form a 2-by-2 dashboard without App-owned native containers.
`ColumnWidths={'1x', 90}` gives a pair a flexible main plot and a fixed-width
scale or histogram; `RowHeights` provides the analogous control for a stack.

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

Declare managed gestures statically on their plot area and provide their
current value in the snapshot:

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

Named contracts also cover anchor paths, paired anchors, fixed point slots,
transient region selection, intervals, and scale references. Apps never author
`Kind`, `Targets`, `Event`, or `Options` transport structs.

Renderer mechanics such as complete clears, empty-state messages, fitting,
fixed-aspect canvases, and axes-relative annotation placement live under
`labkit.app.plot.*`. Apps own when those operations occur, user wording, and
whether a semantic change should preserve or fit the viewport.

## CallbackContext

`labkit.app.CallbackContext` is sealed and exposes specifically named runtime
operations for dialogs, status and diagnostics, runtime sources, render
surfaces, and managed resources. It does
not expose figures, component registries, queues, lifecycle handles, or a
nested service bag.

`postEvent` is the single generic boundary for timer-, serial-, network-, and
monitor-driven refresh. The producer owns protocol and buffering; Runtime owns
coalescing, serialization, validation, presentation, rollback, diagnostics,
and close behavior.

Use `callbackContext.inform(message,title)` for successful or neutral
information; it presents the native information icon. Reserve
`callbackContext.alert(message,title)` for a blocking problem; it presents the
native error icon. Keeping these operations distinct prevents completed INFO
outcomes from inheriting failure styling.

Use context methods only at a callback or reconstruction boundary. Pure
readers, calculations, result builders, and render-model builders accept
ordinary explicit values.

`callbackContext.chooseOption(prompt, choices, ...)` owns ordinary native
confirmation choices. `Title` controls the dialog title, `DefaultChoice`
selects the Enter-key action, and `CancelChoice` is returned when the user
dismisses the dialog. All three named choices must be members of the declared
nonempty unique choice row. File and folder methods remain separate because
they return paths and use platform file choosers. Successful input and output
choices are remembered separately across App windows. A valid App-supplied
start path takes precedence; cancellation or an invalid path does not replace
the last successful folder.

The framework has no generic task-document writer or reader. An App that truly
needs continuation owns the file chooser, archive format, source lookup,
compatibility policy, and reconstruction callback. Returning the reconstructed
application state from that ordinary callback still uses Runtime's normal
validation, presentation, and rollback transaction. Archive files capture one
current/final snapshot; diagnostic state exports remain a separate debugging
facility.

## Diagnostics And Session Logging

Every ordinary App launch starts one sanitized session event stream and durable
journal. Launch arguments do not select a debug mode, change startup behavior,
or generate sample data. Runtime automatically records lifecycle, callback,
transaction, dialog, project, source, result, and failure boundaries with
correlated operation IDs.

App callbacks add domain events through
`callbackContext.log(severity,eventName,message,Name=Value)`. Use `info` for
useful progress and completed user actions, `warning` for recoverable
conditions, and `error` or `critical` for failures. Stable event names and
structured allowlisted attributes support diagnosis; messages remain concise
and safe for display. Pass caught exceptions through the dedicated
`Exception` option instead of copying stack, path, identifier, or scientific
data into free text.

The App's **Tools > Diagnostics** menu opens the live session viewer and exports
a diagnostic bundle from the same session history. Each viewer title names the
App that owns the session. Its single **Level** selector has three modes:
**Full TRACE** displays every retained record, **DEBUG** hides trace-only
stages, and **User** shows user-audience INFO and higher events. Full TRACE is
the default view; it does not manufacture detail that was not captured. The
**Action** filter groups a top-level user or lifecycle action with its nested
callback, dialog, resource, transaction, and—when TRACE capture is active—
presentation records.

Runtime initially captures DEBUG and higher records to bound ordinary-session
cost. The first ERROR or CRITICAL event automatically enables TRACE for later
activity. The viewer also provides an explicit **Enable TRACE** / **Disable
TRACE** control when a user needs detailed capture before an error. TRACE adds
callback state-update and validation stages, successful App/runtime
presentation stages, native presentation commit, and post-failure rollback
cleanup. DEBUG retains ordinary operation start and terminal boundaries plus
all presentation failures, but does not journal successful high-frequency
presentation boundaries. Enabling TRACE never reconstructs earlier detail.
The live viewer appends incoming records to its bounded projection immediately
but batches native table updates at up to 10 Hz. A TRACE burst therefore
causes one table refresh per batch rather than one complete filter, dropdown,
style, and scroll pass per record; manual filters and **Refresh** still apply
immediately. The durable journal and exported bundle retain their independent
bounded histories.

**Export Diagnostic Bundle** writes directly to ignored
`artifacts/diagnostics/` with a generated App-specific, timestamped, unique ZIP
name. Every bundle contains complete sensitive events, attributes, exception
messages, stack locations, and App state. **Complete bundle (exact MAT)**
writes `app-state.mat` unchanged. **Complete bundle (compact synthetic MAT)**
writes `app-state-compact.mat`: Runtime recursively reviews state containers
and replaces supported numeric, logical, character, or string leaves larger
than 1 MiB with deterministic compressible placeholders of the same class and
dimensions. It preserves smaller parameters, annotations, results, and caches.
`bundle-report.json` names structural state paths and sizes for every
replacement without retaining the replaced values; it also lists oversized
unsupported leaf types that had to remain exact. Compact state is diagnostic
evidence, not scientifically valid input. Both modes may contain sensitive
paths, filenames, scientific values, and decoded data; neither is a privacy
filter. Compact is the default; exact remains an explicit choice. If the
session records any ERROR or CRITICAL event, Runtime automatically writes a
compact bundle after the App closes, including the completed close lifecycle
event. A clean session does not create a bundle on close.

If ZIP staging or publication fails, Runtime writes a generated complete-event
text fallback beside that ZIP. Only when automatic output cannot be written
does it ask for another location, with the generated fallback filename already
filled in. Text cannot represent either MAT state and says so explicitly. The
success or fallback alert reports the complete destination path.
Journal degradation remains visible in the surviving in-memory stream; logging
failures never alter callback transaction semantics or scientific results.
A callback exception is recorded as an ERROR with `failed` operation result,
rollback disposition, safe exception identifier, and sanitized function stack.

Runtime close is also an instrumented lifecycle operation. Resource and native
adapter cleanup continue independently; a cleanup exception is retained and
persisted before the journal closes, then returned to the caller. Diagnostics
cannot manufacture evidence for a native event that never entered Runtime, an
exception swallowed by App code without logging, or a MATLAB process that
hangs or terminates before a terminal event. In those cases the last retained
DEBUG boundary and durable journal state are the available evidence.

## Synthetic Inputs

An App that declares `BuildSyntheticSample` exposes **Tools > Developer
Tools > Generate Synthetic Inputs...**. The action creates an anonymous,
validated `labkit.app.synthetic.Pack` and its declared artifacts in a new
folder beneath the selected destination. The pack remains an in-memory return
value; the framework does not publish a second manifest format. Generation does not load the
pack, replace the open task, or suppress `OnStart`; every App launch follows
the same startup path. Users deliberately import generated files through the
App's ordinary controls.

## App-Owned Results And Continuation

Apps write final result files directly. Crop-like workflows may read their
final manifest to reconstruct a task; an editor such as Video Marker may work
directly in an App-owned MAT archive. Other Apps do not gain save/open behavior
merely because they have structured runtime state.

An App with continuation owns its buttons, format, current-version validation,
path policy, and resume meaning. The runtime supplies no envelope, migration
loop, atomic-save policy, project menu, or generic result manifest.

Resources use App-owned IDs. Replacing the same ID is idempotent; Apps remove
resources when a workflow no longer needs them, and the runtime cleans every
surviving resource on close.

## Validation

Use focused contract tests for Definition, layout, callbacks, snapshots,
state invariants, and runtime transactions. Add downstream App tests for changed
behavior and a bounded hidden-GUI test for native wiring. Automated hidden GUI
tests do not prove dialog quality, pointer feel, scientific validity, or a
complete interactive workflow.

See [Testing](../../development/maintain-and-release/testing.md) and
[Build A Complete App](../../development/build-apps/complete-app.md).
