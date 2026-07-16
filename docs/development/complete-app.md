# Build A Complete App

[App development](app-development.md) | [Runtime field reference](../framework/runtime.md#definition-component-contract) | [Testing](testing.md)

This tutorial assembles one complete LabKit app. A developer should be able to
create these files, replace the example calculation with domain code, and
obtain a valid app without inferring hidden lifecycle or UI conventions.

The example opens one numeric text file, applies a gain, previews the result,
and stores a summary table. Its calculation is intentionally simple; the file
boundaries and contracts are the important part.

## Resulting File Tree

```text
apps/example/trace_viewer/
|-- labkit_TraceViewer_app.m
`-- +trace_viewer/
    |-- definition.m
    |-- definitionActions.m
    |-- requirements.m
    |-- version.m
    |-- +appLifecycle/
    |   |-- createProject.m
    |   |-- createSession.m
    |   `-- validateProject.m
    |-- +sourceFiles/
    |   `-- readTrace.m
    |-- +analysisRun/
    |   `-- applyGain.m
    `-- +userInterface/
        |-- buildWorkbenchLayout.m
        |-- presentWorkbench.m
        `-- drawTrace.m
```

`trace_viewer` is the owning MATLAB package. `sourceFiles` and `analysisRun`
name concrete workflow capabilities. There is no app-owned runtime, registry,
generic `helpers`, or direct UI-handle layer.

## 1. Add The Thin Entrypoint

`labkit_TraceViewer_app.m` delegates launch, dependency checks, version
metadata, debug mode, and returned outputs to the framework:

```matlab
function varargout = labkit_TraceViewer_app(varargin)
%LABKIT_TRACEVIEWER_APP Inspect a scaled numeric trace.
    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @trace_viewer.definition, @trace_viewer.requirements, ...
        @trace_viewer.version, varargin{:});
end
```

Do not create figures, add paths, parse files, or run analysis here.

## 2. Declare Requirements And Version

`+trace_viewer/requirements.m` states the reusable LabKit contracts the app
uses:

```matlab
function requirements = requirements()
    requirements = labkit.contract.requirements("ui", ">=7 <8");
end
```

`+trace_viewer/version.m` supplies launcher and window metadata. This semantic
version is the app release version, not the saved-project payload version:

```matlab
function info = version()
    info = struct( ...
        "name", "labkit_TraceViewer_app", ...
        "displayName", "Trace Viewer", ...
        "family", "Example", ...
        "version", "1.0.0", ...
        "updated", "2026-07-16");
end
```

## 3. Define The Durable Project

`+appLifecycle/createProject.m` returns only serializable, authoritative data:

```matlab
function project = createProject()
    project = struct();
    project.inputs = struct( ...
        "sources", labkit.ui.runtime.emptySourceRecords());
    project.parameters = struct("gain", 1);
    project.annotations = struct();
    project.results = struct("summary", table());
    project.extensions = struct();
end
```

The source record and gain must survive reopen, so they are project data. The
decoded numeric vector can be rebuilt from the source and therefore is not.

`+appLifecycle/validateProject.m` checks the complete durable shape after
creation, load, migration, and every action transaction:

```matlab
function accepted = validateProject(project)
    buckets = ["inputs", "parameters", "annotations", ...
        "results", "extensions"];
    assert(isstruct(project) && isscalar(project) && ...
        all(isfield(project, cellstr(buckets))), ...
        "trace_viewer:InvalidProject", ...
        "Trace Viewer project buckets are incomplete.");
    assert(isfield(project.inputs, "sources") && ...
        isfield(project.parameters, "gain") && ...
        isfield(project.results, "summary"), ...
        "trace_viewer:InvalidProject", ...
        "Trace Viewer project fields are incomplete.");
    gain = double(project.parameters.gain);
    assert(isscalar(gain) && isfinite(gain), ...
        "trace_viewer:InvalidProject", ...
        "Gain must be one finite scalar.");
    accepted = true;
end
```

Validation errors name the broken field and use an app-owned identifier. A
validator does not repair data or access the UI.

## 4. Define The Transient Session

`+appLifecycle/createSession.m` rebuilds decoded data and current view state.
The Runtime has already resolved portable source records before calling this
function while opening a project, so the first useful view can be reconstructed
without storing decoded arrays in the project.

```matlab
function session = createSession(project)
    sourcePath = "";
    rawTrace = zeros(0,1);
    if ~isempty(project.inputs.sources)
        sourcePath = string( ...
            project.inputs.sources(1).reference.originalPath);
    end
    if strlength(sourcePath) > 0 && isfile(sourcePath)
        rawTrace = trace_viewer.sourceFiles.readTrace(sourcePath);
    end
    [scaledTrace, ~] = trace_viewer.analysisRun.applyGain( ...
        rawTrace, project.parameters.gain);
    session = struct( ...
        "selection", struct(), ...
        "workflow", struct("logLines", strings(0,1)), ...
        "view", struct(), ...
        "cache", struct("sourcePath", sourcePath, ...
            "rawTrace", rawTrace, "scaledTrace", scaledTrace));
end
```

Project and session are value structs. Graphics, readers, listeners, timers,
and cleanup functions belong to framework-managed resources instead.

The runtime resolves each portable source record before `createSession` runs.
The path used by app code is therefore
`project.inputs.sources(k).reference.originalPath`; there is no
`sources(k).originalPath` shortcut. See
[Runtime and Lifecycle](../framework/runtime.md#portable-source-records) for
the complete record shape and relinking behavior.

## 5. Implement GUI-Free Workflow Functions

`+sourceFiles/readTrace.m` owns the accepted file contract:

```matlab
function trace = readTrace(filepath)
    filepath = string(filepath);
    if strlength(filepath) == 0 || ~isfile(filepath)
        error("trace_viewer:SourceNotFound", ...
            "The selected trace file was not found.");
    end
    value = readmatrix(filepath);
    if ~isnumeric(value) || isempty(value)
        error("trace_viewer:InvalidSource", ...
            "The trace file must contain numeric values.");
    end
    trace = double(value(:,1));
end
```

`+analysisRun/applyGain.m` is deterministic and has no UI or file writes:

```matlab
function [scaled, summary] = applyGain(trace, gain)
    trace = double(trace(:));
    gain = double(gain);
    if ~isscalar(gain) || ~isfinite(gain)
        error("trace_viewer:InvalidGain", ...
            "Gain must be one finite scalar.");
    end
    scaled = trace .* gain;
    summary = table(numel(scaled), mean(scaled, "omitnan"), ...
        "VariableNames", {"sample_count", "mean_value"});
end
```

Direct unit tests should call these functions without starting the app.

## 6. Register Semantic Actions

`+trace_viewer/definitionActions.m` maps stable event IDs to workflow
transactions. Every registered handler uses the canonical signature
`state = action(state,event,services)` (the local function may have a more
specific verb name):

```matlab
function actions = definitionActions()
    actions = struct( ...
        "openTrace", @onOpenTrace, ...
        "gainChanged", @onGainChanged, ...
        "runAnalysis", @onRunAnalysis);
end

function state = onOpenTrace(state, event, services)
    paths = services.events.paths(event, "files");
    if isempty(paths)
        return;
    end
    try
        trace = trace_viewer.sourceFiles.readTrace(paths(1));
    catch ME
        services.diagnostics.report("Trace load failed", ME);
        services.dialogs.alert(ME.message, "Could not load trace");
        return;
    end
    state.project.inputs.sources = services.project.sourceRecord( ...
        "trace", "numericTrace", paths(1), true);
    state.project.results.summary = table();
    state.session.cache.sourcePath = paths(1);
    state.session.cache.rawTrace = trace;
    state.session.cache.scaledTrace = trace;
    state = services.workflow.log(state, "Loaded trace: " + paths(1));
end

function state = onGainChanged(state, ~, ~)
    gain = double(state.project.parameters.gain);
    if ~isscalar(gain) || ~isfinite(gain)
        gain = 1;
    end
    state.project.parameters.gain = gain;
    state.project.results.summary = table();
end

function state = onRunAnalysis(state, ~, services)
    if isempty(state.session.cache.rawTrace)
        services.dialogs.alert("Open a trace first.", "No trace");
        return;
    end
    [scaled, summary] = trace_viewer.analysisRun.applyGain( ...
        state.session.cache.rawTrace, state.project.parameters.gain);
    state.session.cache.scaledTrace = scaled;
    state.project.results.summary = summary;
    state = services.workflow.log(state, "Trace analysis complete.");
end
```

Handlers own workflow order and user wording. They consume normalized events,
call app-owned functions, update state, and use injected services for dialogs,
portable sources, diagnostics, and logs.

## 7. Declare The Layout

`+userInterface/buildWorkbenchLayout.m` returns semantic data only:

```matlab
function layout = buildWorkbenchLayout(callbacks, ~)
    source = labkit.ui.layout.tab("source", "Source", { ...
        labkit.ui.layout.section("sourceSection", "Trace", { ...
            labkit.ui.layout.filePanel("traceFile", "Trace file", ...
                "mode", "single", ...
                "filters", {'*.csv;*.txt', 'Numeric text files'}, ...
                "chooseLabel", "Open trace", ...
                "onChoose", callbacks.openTrace), ...
            labkit.ui.layout.field("gain", "Gain", ...
                "kind", "number", "value", 1, ...
                "Bind", "project.parameters.gain", ...
                "Event", "gainChanged"), ...
            labkit.ui.layout.action("runAnalysis", "Run analysis", ...
                callbacks.runAnalysis, "enabled", false), ...
            labkit.ui.layout.resultTable("summaryTable", "Summary", ...
                "columns", {'Samples','Mean'}, "data", cell(0,2))})});
    log = labkit.ui.layout.tab("log", "Log", { ...
        labkit.ui.layout.section("logSection", "Log", { ...
            labkit.ui.layout.logPanel("appLog", "Log")})});
    preview = labkit.ui.layout.workspace("traceWorkspace", ...
        "Trace Preview", { ...
            labkit.ui.layout.previewArea("traceAxes", "Trace")});
    layout = labkit.ui.layout.workbench("traceViewerApp", ...
        "Trace Viewer", "controlTabs", {source, log}, ...
        "workspace", preview, ...
        "usage", {"Open a trace.", "Set gain and run analysis."});
end
```

Every ID is unique. Callback fields come from registered action IDs. A bound
field names a durable state path and may emit its registered semantic `Event`
after the runtime stages the value.

## 8. Present State And Draw The Preview

`+userInterface/presentWorkbench.m` maps state to semantic properties and a
prepared renderer model:

```matlab
function view = presentWorkbench(state)
    sources = state.project.inputs.sources;
    files = struct("id", {}, "path", {}, "status", {});
    if ~isempty(sources)
        path = string(sources(1).reference.originalPath);
        files = struct("id", "trace", "path", path, "status", "");
    end
    view.controls.traceFile = struct( ...
        "Files", files, "Status", state.session.cache.sourcePath);
    view.controls.runAnalysis = struct( ...
        "Enabled", ~isempty(state.session.cache.rawTrace));
    summary = state.project.results.summary;
    if isempty(summary)
        data = cell(0,2);
    else
        data = {summary.sample_count(1), summary.mean_value(1)};
    end
    view.controls.summaryTable = struct("Data", data);
    model = struct("values", state.session.cache.scaledTrace);
    view.previews.traceAxes = struct( ...
        "Renderer", "trace", "Model", model);
end
```

`+userInterface/drawTrace.m` owns graphics only:

```matlab
function drawTrace(ax, model)
    labkit.ui.plot.clear(ax, "ResetScale", true);
    if isempty(model.values)
        labkit.ui.plot.message(ax, "Open a trace to preview it.");
        return;
    end
    plot(ax, model.values);
    xlabel(ax, "Sample");
    ylabel(ax, "Scaled value");
    grid(ax, "on");
end
```

The presenter does not open files or draw. The renderer does not modify state
or dispatch workflow events.

## 9. Assemble The Definition

`+trace_viewer/definition.m` connects every component:

```matlab
function def = definition()
    project = struct( ...
        "Version", 1, ...
        "Create", @trace_viewer.appLifecycle.createProject, ...
        "Validate", @trace_viewer.appLifecycle.validateProject, ...
        "Migrations", {{}});
    def = labkit.ui.runtime.define( ...
        "Id", "trace_viewer", ...
        "Title", "Trace Viewer", ...
        "Project", project, ...
        "CreateSession", @trace_viewer.appLifecycle.createSession, ...
        "Layout", @trace_viewer.userInterface.buildWorkbenchLayout, ...
        "Actions", trace_viewer.definitionActions(), ...
        "Present", @trace_viewer.userInterface.presentWorkbench, ...
        "Renderers", struct("trace", ...
            @trace_viewer.userInterface.drawTrace));
end
```

The runtime parses this definition immediately, rejects missing or malformed
components, creates and validates the project, creates the session, builds the
layout, presents the first state, and then accepts queued semantic actions.

## 10. Add Tests Before Expanding The App

At minimum, add:

- a unit test for `readTrace` accepted/rejected shapes;
- a numeric unit test for `applyGain`, including nonfinite behavior;
- a project factory/validator test;
- a hidden GUI test that launches the app, supplies a synthetic file through
  the workflow driver, runs analysis, checks the table and preview, saves the
  project, reloads it, and verifies rebuildable session data;
- version, manual, and component-history updates for user-visible behavior.

Use exact files during iteration:

```matlab
addpath("tests")
runLabKitTests("Files", ...
    "tests/cases/unit/apps/example/TraceViewerTest.m", ...
    "HtmlReport", false)
```

See [Testing](testing.md) for GUI mode, changed-file routing, and final gates.

## Completion Checklist

- The entrypoint only launches.
- `definition.m` only connects validated components.
- Project data are authoritative and serializable; session data are transient
  and rebuildable.
- Actions use semantic events and injected services.
- Layout is data-only, presentation is pure, and renderers draw prepared
  models.
- Domain calculations and file rules are GUI-free and directly tested.
- Public behavior, version, component history, and app manual change together.
