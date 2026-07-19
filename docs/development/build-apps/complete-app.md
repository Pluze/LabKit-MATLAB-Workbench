# Build A Complete App

[App development](app-development.md) | [Framework](../../framework/README.md) | [Testing](../maintain-and-release/testing.md)

This tutorial shows the production explicit UI contract. The example opens
numeric trace files, binds a gain parameter, previews the selected traces, and
declares one export Command.

## File Shape

```text
apps/example/trace_viewer/
|-- labkit_TraceViewer_app.m
`-- +trace_viewer/
    |-- definition.m
    |-- projectSpec.m
    |-- createSession.m
    |-- definitionActions.m
    |-- +sourceFiles/readTrace.m
    `-- +userInterface/
        |-- buildWorkbenchLayout.m
        |-- presentWorkbench.m
        `-- renderTrace.m
```

A static App can omit the project, session, Commands, presenter, and renderer.

## 1. Thin Entrypoint

```matlab
function varargout = labkit_TraceViewer_app(varargin)
%LABKIT_TRACEVIEWER_APP Inspect scaled numeric traces.
    app = trace_viewer.definition();
    [varargout{1:nargout}] = app.launch(varargin{:});
end
```

## 2. One Application Contract

```matlab
function app = definition()
    commands = trace_viewer.definitionActions();
    app = labkit.ui.Application( ...
        Command="labkit_TraceViewer_app", ...
        Id="trace_viewer", ...
        Title="Trace Viewer", ...
        Family="Examples", ...
        AppVersion="1.0.0", ...
        Updated="2026-07-19", ...
        Requirements=labkit.contract.requirements("ui", ">=8 <9"), ...
        Project=trace_viewer.projectSpec(), ...
        Session=@trace_viewer.createSession, ...
        Layout=trace_viewer.userInterface.buildWorkbenchLayout(commands), ...
        Present=@trace_viewer.userInterface.presentWorkbench, ...
        Renderers=struct( ...
            "trace", @trace_viewer.userInterface.renderTrace));
end
```

Layout automatically registers referenced Commands. Do not duplicate them in
Application. Omit `Capabilities` unless the App needs an advanced strict
allow-list audit.

## 3. Durable Project

```matlab
function contract = projectSpec()
    contract = labkit.ui.ProjectContract( ...
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

Use `labkit.ui.ProjectContract()` when any scalar struct is sufficient. For a
later payload version, add the one fixed
`project = migrate(project,fromVersion)` callback. Framework owns the ordered
migration loop and project envelope.

## 4. Transient Session

```matlab
function session = createSession(project, context)
    paths = context.sourcePaths(project.inputs.sources);
    traces = cell(numel(paths), 1);
    for k = 1:numel(paths)
        traces{k} = trace_viewer.sourceFiles.readTrace(paths(k));
    end
    session = struct( ...
        "selection", struct("files", ...
            labkit.ui.Selection(Indices=1:numel(paths))), ...
        "cache", struct("traces", {traces}));
end
```

Portable source records are opaque. Resolve them with `context.sourcePaths`;
do not read their representation. A standard file collection change reruns
this factory transactionally. A selection-only change does not reload files.

## 5. Semantic Layout

```matlab
function layout = buildWorkbenchLayout(commands)
    controls = { ...
        labkit.ui.Layout.filePanel("files", ...
            Filters=["*.csv", "CSV files (*.csv)"], ...
            Bind="project.inputs.sources", ...
            SelectionBind="session.selection.files", ...
            SourceRole="trace", SourceIdPrefix="trace"), ...
        labkit.ui.Layout.field("gain", Label="Gain", ...
            Kind="numeric", Bind="project.parameters.gain"), ...
        labkit.ui.Layout.action("export", "Export", commands.export)};
    workspace = labkit.ui.Layout.workspace( ...
        labkit.ui.Layout.previewArea("preview", ...
            AxisIds="trace", Renderers="trace"));
    layout = labkit.ui.Layout.workbench(controls, Workspace=workspace);
end
```

The file panel and gain field need no callbacks. Runtime owns file
add/remove/clear, selection, state writes, and their default presentation.

## 6. Dynamic Presentation

```matlab
function view = presentWorkbench(state)
    selected = state.session.selection.files.Indices;
    traces = state.session.cache.traces(selected);
    model = struct( ...
        "traces", {traces}, ...
        "gain", state.project.parameters.gain);
    view = labkit.ui.Presentation() ...
        .enabled("export", ~isempty(traces)) ...
        .plot("preview", "trace", model);
end
```

The App returns only derived dynamic operations. Runtime completes the snapshot
from Layout defaults, bindings, file state, and framework log/status state.

## 7. Renderer

```matlab
function renderTrace(axes, model)
    ax = axes(1);
    labkit.ui.plot.clear(ax, ResetScale=true);
    hold(ax, "on");
    for k = 1:numel(model.traces)
        values = model.gain .* model.traces{k};
        plot(ax, 1:numel(values), values);
    end
    hold(ax, "off");
    xlabel(ax, "Sample");
    ylabel(ax, "Scaled value");
end
```

Every renderer has exactly two inputs and no output. Multi-axis previews
receive axes in `AxisIds` order. Apps never receive a component registry.

## 8. Business Command And Result

```matlab
function commands = definitionActions()
    commands = struct( ...
        "export", labkit.ui.Command("export", @exportTrace));
end

function state = exportTrace(state, context)
    chosen = context.chooseOutputFile( ...
        ["*.csv", "CSV files (*.csv)"], pwd);
    if chosen.Cancelled
        return;
    end
    outputPath = string(chosen.Value);
    writematrix(state.session.cache.traces{1}, outputPath);
    [folder, name, extension] = fileparts(outputPath);
    output = labkit.ui.ResultOutput( ...
        "trace", "primary", string(name) + string(extension), ...
        MediaType="text/csv");
    result = labkit.ui.Result( ...
        Outputs={output}, Inputs=struct( ...
            "sources", state.project.inputs.sources), ...
        Parameters=state.project.parameters, ...
        Summary=struct("traceCount", ...
            numel(state.session.cache.traces)));
    context.writeResult(folder, result);
    context.appendStatus("Exported " + outputPath);
end
```

Cancellation is explicit in `DialogResult`. Runtime result writing owns
provenance, checksums, file sizes, and atomic manifest replacement.

## Validation

Test readers, calculations, project validation, Commands, and presenters
without a GUI first. Add one hidden GUI workflow for semantic construction,
native callback wiring, rendering, file lifecycle, export, and project
restore. Hidden GUI automation does not validate native dialog feel or the
scientific suitability of a workflow.
