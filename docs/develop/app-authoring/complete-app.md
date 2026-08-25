# Build A Complete App

```labkit-page
id: develop-build-apps-complete-app
type: tutorial
audience: app-developer
summary: Build a small trace viewer with the production labkit.app contract, App-owned state, decoded data, plotting, and result export.
```

This guide builds a small trace viewer with the production `labkit.app` contract. The example keeps App-owned runtime settings and decoded file data, draws a plot, and exports a result. It does not define a task archive. Each file has one visible responsibility.

## File Shape

```text
apps/examples/trace_viewer/
|-- labkit_TraceViewer_app.m
`-- +trace_viewer/
    |-- definition.m
    |-- createState.m
    |-- refreshState.m
    |-- +workbench/
    |   |-- buildLayout.m
    |   `-- present.m
    |-- +sourceTrace/
    |   |-- readTrace.m
    |   |-- layoutSection.m
    |   |-- workspacePlot.m
    |   |-- present.m
    |   `-- draw.m
    `-- +resultFiles/
        |-- layoutSection.m
        `-- exportTrace.m
```

There is no handler table, renderer registry, or `+userInterface` bucket. `+workbench` is the product assembly boundary. Capability packages own their part of the user workflow.

## 1. Thin Entrypoint

```matlab
function varargout = labkit_TraceViewer_app(varargin)
[varargout{1:nargout}] = trace_viewer.definition().launch(varargin{:});
end
```

The entrypoint does not build state, controls, services, or figures.

## 2. One App Definition

```matlab
function app = definition()
app = labkit.app.Definition( ...
    Entrypoint="labkit_TraceViewer_app", ...
    AppId="examples.trace-viewer", ...
    Title="Trace Viewer", ...
    Family="Examples", ...
    AppVersion="1.0.0", ...
    Updated="2026-07-19", ...
    CreateState=@trace_viewer.createState, ...
    RefreshState=@trace_viewer.refreshState, ...
    Workbench=trace_viewer.workbench.buildLayout(), ...
    PresentWorkbench=@trace_viewer.workbench.present);
end
```

Definition is a readable inventory, not an execution script. It validates the static layout, direct callback signatures, plot renderers, target IDs, state callbacks, and presentation contract before native UI mutation.

## 3. App-Owned Runtime State

```matlab
function state = createState(callbackContext, ~)
project = struct( ...
    "inputs", struct("sources", labkit.app.source.emptyRecords()), ...
    "parameters", struct("gain", 1), ...
    "results", struct("lastExport", []));
state = struct("project", project, "session", struct("trace", struct("x", [], "y", [])));
state = trace_viewer.refreshState(state, callbackContext);
end
```

The bucket names are App conventions only. The framework treats the complete scalar struct as opaque runtime state and provides no save/open semantics.

## 4. Refresh After Source Changes

```matlab
function state = refreshState(state, callbackContext)
paths = labkit.app.source.paths(state.project.inputs.sources);
trace = struct("x", [], "y", []);
if ~isempty(paths)
    trace = trace_viewer.sourceTrace.readTrace(paths(1));
end
state.session.trace = trace;
end
```

The runtime calls `RefreshState` after file-list source changes. If this App later needs continuation, it must design its own explicit final-state archive; the framework does not serialize either bucket.

## 5. Product Layout

```matlab
function layout = buildLayout()
controls = { ...
    trace_viewer.sourceTrace.layoutSection(), ...
    trace_viewer.resultFiles.layoutSection()};
workspace = labkit.app.layout.workspace( ...
    trace_viewer.sourceTrace.workspacePlot());
layout = labkit.app.layout.workbench( ...
    controls, Workspace=workspace);
end
```

The assembly reads in user order. A complex App can use tabs and workspace pages here without flattening every feature into one file.

The source capability owns its controls:

```matlab
function section = layoutSection()
section = labkit.app.layout.section("sourceTrace", "Trace", { ...
    labkit.app.layout.fileList("traceFiles", ...
        Label="Trace file", ...
        SelectionMode="single", ...
        Bind="project.inputs.sources", ...
        SourceRole="trace", ...
        SourceIdPrefix="trace"), ...
    labkit.app.layout.slider("gain", ...
        Label="Gain", Limits=[0.1 10], ...
        Bind="project.parameters.gain")});
end
```

Standard fields and file lists need no App callback. Their bindings update canonical state transactionally.

The result capability binds a real business action directly:

```matlab
function section = layoutSection()
section = labkit.app.layout.section("resultFiles", "Results", { ...
    labkit.app.layout.button("exportTrace", ...
        "Export trace", @trace_viewer.resultFiles.exportTrace, ...
        Tooltip="Export the calibrated trace and its sampling metadata.")});
end
```

## 6. Complete View Snapshot

```matlab
function view = present(applicationState)
view = labkit.app.view.Snapshot();
view = view.include(trace_viewer.sourceTrace.present( ...
    applicationState.session.trace, ...
    applicationState.project.parameters.gain));
view = view.enabled("exportTrace", ...
    ~isempty(applicationState.session.trace.x));
end
```

`+workbench/present.m` is a short assembly boundary. It extracts exact inputs and composes feature fragments with `Snapshot.include`; it does not perform IO or calculation.

```matlab
function view = present(trace, gain)
model = struct("x", trace.x, "y", trace.y .* gain);
view = labkit.app.view.Snapshot().renderPlot("tracePlot", model);
end
```

## 7. Feature-Owned Renderer

```matlab
function node = workspacePlot()
node = labkit.app.layout.plotArea( ...
    "tracePlot", @trace_viewer.sourceTrace.draw);
end

function draw(axesById, model)
ax = axesById.main;
cla(ax);
plot(ax, model.x, model.y);
xlabel(ax, "Time (s)");
ylabel(ax, "Signal");
grid(ax, "on");
end
```

The plot area references the concrete renderer. The model carries prepared App meaning; drawing does not create runtime state or dispatch workflow actions.

## 8. Direct Business Callback

```matlab
function applicationState = exportTrace( ...
        applicationState, callbackContext)
trace = applicationState.session.trace;
gain = applicationState.project.parameters.gain;
choice = callbackContext.chooseOutputFile( ...
    {"*.csv", "CSV files"}, "");
if choice.Cancelled
    return;
end

tableValue = table(trace.x(:), trace.y(:) .* gain, ...
    VariableNames=["Time", "Signal"]);
writetable(tableValue, choice.Value);
applicationState.project.results.lastExport = string(choice.Value);
end
```

The callback signature exposes its runtime boundary. For larger exports, delegate table construction and result packaging to functions that accept only the trace, gain, and destination they require.

## Validation

Test readers, calculations, state transitions, snapshot fragments, renderers, and exports directly with synthetic values. Construct `definition()` in a headless test to validate the whole static contract. Run the App's bounded hidden-GUI workflow after smaller tests are stable; native dialogs and visual quality still require developer-led interactive validation.

Before merge, update the App version, owning manual, structured component history, generated documentation site, and the final branch validation gates.

## Related Documentation

- [App Development](app-development.md)
- [Architecture](architecture.md)
- [LabKit App SDK](../framework/README.md)
- [Testing](../testing.md)
