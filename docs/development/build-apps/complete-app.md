# Build A Complete App

[App development](app-development.md) | [Framework](../../framework/README.md) | [Testing](../maintain-and-release/testing.md)

This tutorial shows the production App SDK contract. The example opens
numeric trace files, binds a gain parameter, previews the selected traces, and
declares one export handler.

## File Shape

```text
apps/example/trace_viewer/
|-- labkit_TraceViewer_app.m
`-- +trace_viewer/
    |-- definition.m
    |-- projectSpec.m
    |-- createSession.m
    |-- stateHandlers.m
    |-- +sourceFiles/readTrace.m
    `-- +userInterface/
        |-- buildWorkbenchLayout.m
        |-- presentWorkbench.m
        `-- renderTrace.m
```

A static App can omit the project, session, handlers, view builder, and renderer.

## 1. Thin Entrypoint

```matlab
function varargout = labkit_TraceViewer_app(varargin)
%LABKIT_TRACEVIEWER_APP Inspect scaled numeric traces.
    app = trace_viewer.definition();
    [varargout{1:nargout}] = app.launch(varargin{:});
end
```

## 2. One App Definition

```matlab
function app = definition()
    app = labkit.app.Definition( ...
        Entrypoint="labkit_TraceViewer_app", ...
        AppId="trace_viewer", ...
        Title="Trace Viewer", ...
        Family="Examples", ...
        AppVersion="1.0.0", ...
        Updated="2026-07-19", ...
        Requirements=labkit.contract.requirements("app", ">=1 <2"), ...
        ProjectSchema=trace_viewer.projectSpec(), ...
        CreateSession=@trace_viewer.createSession, ...
        Workbench=trace_viewer.userInterface.buildWorkbenchLayout(), ...
        BuildView=@trace_viewer.userInterface.presentWorkbench, ...
        Renderers=struct( ...
            "trace", @trace_viewer.userInterface.renderTrace));
end
```

Layout automatically registers referenced StateHandlers. Do not duplicate
them in Definition. Omit `StrictCapabilities` unless the App needs an advanced
allow-list audit.

## 3. Durable Project

```matlab
function contract = projectSpec()
    contract = labkit.app.project.Schema( ...
        Version=1, Create=@createProject, Validate=@validateProject);
end

function project = createProject()
    project = struct( ...
        "inputs", struct("sources", struct([])), ...
        "parameters", struct("gain", 1), ...
        "results", struct());
end

function accepted = validateProject(project)
    accepted = isstruct(project) && isscalar(project) && ...
        isfield(project, "inputs") && ...
        isstruct(project.inputs.sources) && ...
        isfield(project, "parameters") && ...
        isnumeric(project.parameters.gain) && ...
        isscalar(project.parameters.gain) && ...
        isfinite(project.parameters.gain);
end
```

Use `labkit.app.project.Schema()` when any scalar struct is sufficient. For a
later payload version, add the one fixed
`project = migrate(project,fromVersion)` callback. Framework owns the ordered
migration loop and project envelope.

## 4. Transient Session

```matlab
function session = createSession(project, context)
    arguments
        project (1, 1) struct
        context (1, 1) labkit.app.CallbackContext
    end
    paths = context.resolveSourcePaths(project.inputs.sources);
    traces = cell(numel(paths), 1);
    for k = 1:numel(paths)
        traces{k} = trace_viewer.sourceFiles.readTrace(paths(k));
    end
    session = struct( ...
        "selection", struct("files", ...
            labkit.app.event.ListSelection(Indices=1:numel(paths))), ...
        "cache", struct("traces", {traces}));
end
```

Portable source records are opaque. Resolve them with
`context.resolveSourcePaths`;
do not read their representation. A standard file collection change reruns
this factory transactionally. A selection-only change does not reload files.

## 5. Semantic Layout

```matlab
function layout = buildWorkbenchLayout()
    handlers = trace_viewer.stateHandlers();
    controls = { ...
        labkit.app.layout.fileList("files", ...
            Filters=["*.csv", "CSV files (*.csv)"], ...
            Bind="project.inputs.sources", ...
            SelectionBind="session.selection.files", ...
            SourceRole="trace", SourceIdPrefix="trace"), ...
        labkit.app.layout.field("gain", Label="Gain", ...
            Kind="numeric", Bind="project.parameters.gain"), ...
        labkit.app.layout.button("export", "Export", handlers.export)};
    workspace = labkit.app.layout.workspace( ...
        labkit.app.layout.plotArea("preview", ...
            AxisIds="trace", Renderers="trace"));
    layout = labkit.app.layout.workbench(controls, Workspace=workspace);
end
```

The file list and gain field need no callbacks. Runtime owns file
add/remove/clear, selection, state writes, and their default presentation.

## 6. Dynamic View Snapshot

```matlab
function view = presentWorkbench(state)
    selected = state.session.selection.files.Indices;
    traces = state.session.cache.traces(selected);
    model = struct( ...
        "traces", {traces}, ...
        "gain", state.project.parameters.gain);
    view = labkit.app.view.Snapshot() ...
        .enabled("export", ~isempty(traces)) ...
        .renderPlot("preview", "trace", model);
end
```

The App returns only derived dynamic operations. Runtime completes the snapshot
from layout defaults, bindings, file state, and framework log/status state.

## 7. Renderer

```matlab
function renderTrace(axes, model)
    ax = axes(1);
    cla(ax, "reset");
    hold(ax, "on");
    for k = 1:numel(model.traces)
        values = model.gain .* model.traces{k};
        plot(ax, 1:numel(values), values);
    end
    hold(ax, "off");
    axis(ax, "tight");
    xlabel(ax, "Sample");
    ylabel(ax, "Scaled value");
end
```

Every renderer has exactly two inputs and no output. Multi-axis previews
receive axes in `AxisIds` order. Apps never receive a component registry.

## 8. Business Handler And Result

```matlab
function handlers = stateHandlers()
    handlers = struct( ...
        "export", labkit.app.StateHandler("export", @exportTrace));
end

function state = exportTrace(state, context)
    arguments
        state (1, 1) struct
        context (1, 1) labkit.app.CallbackContext
    end
    chosen = context.chooseOutputFile( ...
        ["*.csv", "CSV files (*.csv)"], pwd);
    if chosen.Cancelled
        return;
    end
    outputPath = string(chosen.Value);
    writematrix(state.session.cache.traces{1}, outputPath);
    [folder, name, extension] = fileparts(outputPath);
    output = labkit.app.result.File( ...
        "trace", "primary", string(name) + string(extension), ...
        MediaType="text/csv");
    result = labkit.app.result.Package( ...
        Outputs={output}, Inputs=struct( ...
            "sources", state.project.inputs.sources), ...
        Parameters=state.project.parameters, ...
        Summary=struct("traceCount", ...
            numel(state.session.cache.traces)));
    context.writeResultPackage(folder, result);
    context.appendStatus("Exported " + outputPath);
end
```

Cancellation is explicit in `labkit.app.dialog.Choice`. Runtime result writing owns
provenance, checksums, file sizes, and atomic manifest replacement.

## Validation

Test readers, calculations, project validation, StateHandlers, and view builders
without a GUI first. Add one hidden GUI workflow for semantic construction,
native callback wiring, rendering, file lifecycle, export, and project
restore. Hidden GUI automation does not validate native dialog feel or the
scientific suitability of a workflow.
