# Build A Complete App

[App development](app-development.md) | [Runtime field reference](../framework/runtime.md#definition-component-contract) | [Testing](testing.md)

This tutorial builds one current Runtime V2 App without copying historical
lifecycle adapters. The example opens one numeric trace, applies a gain,
previews the result, and keeps a summary in project state.

The important rule is progressive capability: start with three files and add
state or workflow files only when the product actually needs them.

## The Three-File Starting Point

A static App needs only:

```text
apps/example/trace_viewer/
|-- labkit_TraceViewer_app.m
`-- +trace_viewer/
    |-- definition.m
    `-- +userInterface/
        `-- buildWorkbenchLayout.m
```

`labkit.ui.runtime.define` supplies an empty version-1 project, empty session,
empty action registry, empty presenter, and no Start callback. A static layout
therefore launches without `projectSpec.m`, `createSession.m`,
`definitionActions.m`, or `presentWorkbench.m`.

The trace example is interactive and persistent, so its completed tree is:

```text
apps/example/trace_viewer/
|-- labkit_TraceViewer_app.m
`-- +trace_viewer/
    |-- definition.m
    |-- projectSpec.m
    |-- createSession.m
    |-- definitionActions.m
    |-- +sourceFiles/
    |   `-- readTrace.m
    |-- +analysisRun/
    |   `-- applyGain.m
    `-- +userInterface/
        |-- buildWorkbenchLayout.m
        |-- presentWorkbench.m
        `-- renderTrace.m
```

There is no separate `requirements.m`, `version.m`, `+appLifecycle`,
`+appState`, or migration-file collection. Product metadata and optional
capabilities live in `definition.m`; durable schema callbacks are local
functions inside one `projectSpec.m`.

## 1. Add The Thin Entrypoint

`labkit_TraceViewer_app.m` delegates every request to the definition:

```matlab
function varargout = labkit_TraceViewer_app(varargin)
%LABKIT_TRACEVIEWER_APP Inspect a scaled numeric trace.
    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @trace_viewer.definition, varargin{:});
end
```

The entrypoint does not add paths, create figures, parse files, or route
callbacks. The same command handles normal launch, `debug`, `requirements`,
and `version` requests through Runtime V2.

## 2. Declare One Product Contract

`+trace_viewer/definition.m` owns product metadata, facade compatibility, and
the capabilities this App actually uses:

```matlab
function def = definition()
    def = labkit.ui.runtime.define( ...
        "Command", "labkit_TraceViewer_app", ...
        "Id", "trace_viewer", ...
        "Title", "Trace Viewer", ...
        "Family", "Example", ...
        "AppVersion", "1.0.0", ...
        "Updated", "2026-07-16", ...
        "Requirements", labkit.contract.requirements("ui", ">=7 <8"), ...
        "Project", trace_viewer.projectSpec(), ...
        "CreateSession", @trace_viewer.createSession, ...
        "Layout", @trace_viewer.userInterface.buildWorkbenchLayout, ...
        "Actions", trace_viewer.definitionActions(), ...
        "Present", @trace_viewer.userInterface.presentWorkbench, ...
        "Renderers", struct( ...
            "trace", @trace_viewer.userInterface.renderTrace));
end
```

`Id` is the permanent persistence identity, not a display label. Do not change
it after project files exist. `AppVersion` versions the product; project
payload `Version` below versions only the durable data schema.

For the three-file static form, omit `Project`, `CreateSession`, `Actions`,
`Present`, and `Renderers` from this call.

## 3. Own Durable Data In One Project Spec

`+trace_viewer/projectSpec.m` contains the public project-spec entry and local
schema functions:

```matlab
function spec = projectSpec()
    spec = struct( ...
        "Version", 1, ...
        "Create", @createProject, ...
        "Validate", @validateProject, ...
        "Migrate", []);
end

function project = createProject()
    project = struct();
    project.inputs = struct( ...
        "sources", labkit.ui.runtime.emptySourceRecords());
    project.parameters = struct("gain", 1);
    project.annotations = struct();
    project.results = struct("summary", table());
    project.extensions = struct();
end

function accepted = validateProject(project)
    buckets = ["inputs", "parameters", "annotations", ...
        "results", "extensions"];
    assert(isstruct(project) && isscalar(project) && ...
        all(isfield(project, cellstr(buckets))), ...
        "trace_viewer:InvalidProject", ...
        "Trace Viewer project buckets are incomplete.");
    assert(isfield(project.inputs, "sources") && ...
        isstruct(project.inputs.sources), ...
        "trace_viewer:InvalidProject", ...
        "Trace Viewer inputs.sources must contain source records.");
    gain = project.parameters.gain;
    assert(isnumeric(gain) && isscalar(gain) && isfinite(gain), ...
        "trace_viewer:InvalidProject", ...
        "Trace Viewer gain must be one finite numeric scalar.");
    assert(istable(project.results.summary), ...
        "trace_viewer:InvalidProject", ...
        "Trace Viewer summary must be a table.");
    accepted = true;
end
```

The Runtime adds any missing canonical project buckets, then validates the
complete value after creation, load, migration, and every action transaction.
A validator checks; it does not repair, prompt, or access graphics.

When the schema later advances to version 2, change `Version` and provide one
local version-aware function:

```matlab
function project = migrateProject(project, fromVersion)
    switch fromVersion
        case 1
            project.annotations.note = "";
        otherwise
            error("trace_viewer:UnsupportedProjectVersion", ...
                "Cannot migrate payload version %d.", fromVersion);
    end
end
```

Set `"Migrate", @migrateProject`. Runtime calls it once per missing version and
validates every returned payload. Do not create `migrateProjectV1ToV2.m`,
`migrateProjectV2ToV3.m`, and similar files.

## 4. Rebuild Only App-Specific Session Data

`+trace_viewer/createSession.m` reconstructs data that should not be saved:

```matlab
function session = createSession(project)
    sourcePath = labkit.ui.runtime.sourcePaths( ...
        project.inputs.sources, "trace");
    rawTrace = zeros(0, 1);
    if strlength(sourcePath) > 0
        rawTrace = trace_viewer.sourceFiles.readTrace(sourcePath);
    end
    [scaledTrace, ~] = trace_viewer.analysisRun.applyGain( ...
        rawTrace, project.parameters.gain);
    session = struct("cache", struct( ...
        "sourcePath", sourcePath, ...
        "rawTrace", rawTrace, ...
        "scaledTrace", scaledTrace));
end
```

Runtime supplies missing `selection`, `workflow`, `view`, and `cache` buckets.
Return only App-specific fields. During project load, required portable sources
are resolved or interactively relinked before this function runs.

Graphics handles, readers, listeners, timers, and cleanup callbacks do not
belong in project or session values. Register them with Runtime resources.

## 5. Implement GUI-Free Workflow Functions

`+trace_viewer/+sourceFiles/readTrace.m` owns the accepted input:

```matlab
function trace = readTrace(filepath)
    filepath = string(filepath);
    if ~isscalar(filepath) || strlength(filepath) == 0 || ~isfile(filepath)
        error("trace_viewer:SourceNotFound", ...
            "The selected trace file was not found.");
    end
    value = readmatrix(filepath);
    if ~isnumeric(value) || isempty(value)
        error("trace_viewer:InvalidSource", ...
            "The trace file must contain numeric values.");
    end
    trace = double(value(:, 1));
end
```

`+trace_viewer/+analysisRun/applyGain.m` owns the deterministic calculation:

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

Both functions are directly testable without launching the GUI.

## 6. Register Semantic Actions

`+trace_viewer/definitionActions.m` maps layout event IDs to transactions:

```matlab
function actions = definitionActions()
    actions = struct( ...
        "openTrace", @onOpenTrace, ...
        "gainChanged", @onGainChanged, ...
        "runAnalysis", @onRunAnalysis);
end

function state = onOpenTrace(state, ~, services)
    [filepath, cancelled] = services.dialogs.inputFile( ...
        "*.txt;*.csv", "Open numeric trace", ...
        services.dialogs.defaultFolder("input"));
    if cancelled
        return;
    end
    rawTrace = trace_viewer.sourceFiles.readTrace(filepath);
    state.project.inputs.sources = services.project.upsertSource( ...
        state.project.inputs.sources, ...
        "trace", "trace", filepath, true);
    state.session.cache.sourcePath = filepath;
    state.session.cache.rawTrace = rawTrace;
    state = recompute(state);
    state = services.workflow.log(state, "Opened trace: " + filepath);
end

function state = onGainChanged(state, ~, ~)
    state = recompute(state);
end

function state = onRunAnalysis(state, ~, services)
    state = recompute(state);
    state = services.workflow.log(state, "Updated trace summary.");
end

function state = recompute(state)
    [scaled, summary] = trace_viewer.analysisRun.applyGain( ...
        state.session.cache.rawTrace, state.project.parameters.gain);
    state.session.cache.scaledTrace = scaled;
    state.project.results.summary = summary;
end
```

The App owns what each command means. Runtime owns queueing, busy state,
rollback, validation, presentation commit, and error propagation. Use injected
services for dialogs, logging, source identity, results, diagnostics, previews,
and managed resources; do not read registries or UI controls.

## 7. Build A Data-Only Layout

`+trace_viewer/+userInterface/buildWorkbenchLayout.m` describes semantics:

```matlab
function layout = buildWorkbenchLayout()
    commands = labkit.ui.layout.section("commands", "Commands", { ...
        labkit.ui.layout.action("openTrace", "Open trace", "openTrace"), ...
        labkit.ui.layout.field("gain", "Gain", ...
            "kind", "number", ...
            "value", 1, ...
            "Bind", "project.parameters.gain", ...
            "Event", "gainChanged"), ...
        labkit.ui.layout.action( ...
            "runAnalysis", "Run analysis", "runAnalysis")});
    tab = labkit.ui.layout.tab("main", "Trace", {commands});
    workspace = labkit.ui.layout.workspace("workspace", "Trace", { ...
        labkit.ui.layout.previewArea("tracePlot", "Scaled trace"), ...
        labkit.ui.layout.resultTable("summary", "Summary"), ...
        labkit.ui.layout.logPanel("appLog", "Log")});
    layout = labkit.ui.layout.workbench( ...
        "traceViewer", "Trace Viewer", ...
        "controlTabs", {tab}, "workspace", workspace);
end
```

The layout does not create handles, read files, mutate state, choose pixel
geometry, or schedule callbacks. IDs are stable semantic references shared by
the layout, action registry, and presenter.

## 8. Present One Committed View

`+trace_viewer/+userInterface/presentWorkbench.m` converts canonical state to
declarative view models:

```matlab
function view = presentWorkbench(state)
    trace = state.session.cache.scaledTrace;
    view = struct();
    view.controls.summary = struct( ...
        "Data", state.project.results.summary);
    view.previews.tracePlot = struct( ...
        "Renderer", "trace", ...
        "Model", struct( ...
            "x", (1:numel(trace)).', ...
            "y", trace, ...
            "hasData", ~isempty(trace)));
end
```

`+trace_viewer/+userInterface/renderTrace.m` owns drawing only:

```matlab
function renderTrace(ax, model)
    labkit.ui.plot.clear(ax, "ResetScale", true);
    if ~model.hasData
        labkit.ui.plot.message(ax, "Open a trace to begin.");
        return;
    end
    plot(ax, model.x, model.y, "LineWidth", 1.2);
    xlabel(ax, "Sample");
    ylabel(ax, "Scaled value");
    grid(ax, "on");
    labkit.ui.plot.fit(ax);
end
```

Presenters do not write files or mutate state. Renderers do not choose
scientific options or reset zoom for overlay-only edits.

## 9. Validate The Product

At minimum, add:

- GUI-free tests for `readTrace` and `applyGain`
- definition tests for metadata, project creation, validation, and session
  reconstruction
- one hidden GUI workflow covering launch, open, gain change, analysis, save,
  clear, and reopen
- migration tests for every supported prior payload version
- documentation examples that run in a clean MATLAB session

During iteration, run the exact affected files. Use the project test planner
only at a coherent checkpoint; follow [Testing](testing.md) for supported
commands and the distinction between hidden GUI coverage and manual native
dialog/interaction checks.

## Capability Checklist

Add a file only when the answer is yes:

| Need | Add |
| --- | --- |
| Static product metadata and layout | `definition.m`, layout builder |
| User commands or bound events | `definitionActions.m` |
| Dynamic control/preview models | presenter and any renderers |
| Durable App-owned data | `projectSpec.m` |
| Rebuilt decoded/cache/selection state | `createSession.m` |
| Saved schema has changed | local `migrateProject` in `projectSpec.m` |
| Legacy top-level MAT variable is supported | local importer declared by `LegacyImports` |
| Post-layout request/resource initialization | a semantically named optional `Start` function |

This is the current Runtime V2 architecture. Older split metadata files,
generic lifecycle packages, and per-version migration files are retired, not
alternative supported styles.
