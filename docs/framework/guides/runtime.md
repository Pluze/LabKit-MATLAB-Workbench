# Runtime And Lifecycle

`labkit.app` is the App-facing runtime contract. Apps declare product meaning;
the private runtime owns native MATLAB components, event serialization,
transactions, project documents, portable sources, resources, and cleanup.

## Definition And Launch

Each entrypoint delegates to one immutable definition:

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
    Requirements=labkit.contract.requirements("app", ">=1 <2"), ...
    Workbench=example.workbench.buildLayout(), ...
    ProjectSchema=example.projectSpec(), ...
    CreateSession=@example.createSession, ...
    PresentWorkbench=@example.workbench.present);
end
```

Required Definition arguments are product metadata, requirements, and one
`labkit.app.layout.workbench` value. Optional callbacks are:

| Argument | Signature | Purpose |
| --- | --- | --- |
| `CreateSession` | `session = callback(project,callbackContext)` | Rebuild transient App data from durable project state. |
| `PresentWorkbench` | `view = callback(applicationState)` | Return the App-owned fragment of the complete visible snapshot. |
| `OnStart` | `applicationState = callback(applicationState,callbackContext)` | Perform a real post-first-commit request or resource initialization. |
| `BuildDebugSample` | `sample = callback(callbackContext)` | Build clean-room debug input when the App supports it. |

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
            "Export", @example.resultFiles.exportResult)})};
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

Runtime state always has two App-owned buckets:

```matlab
applicationState.project
applicationState.session
```

`project` is durable, validated meaning. `session` is transient and
reconstructible. A callback receives the previous complete state and returns a
candidate complete state. The runtime:

1. serializes the event;
2. invokes the direct callback;
3. validates project and session shape;
4. builds and validates the complete view snapshot;
5. reconciles native components;
6. publishes state and view together.

Failure rolls back both state and presentation and clears event-scoped
resources. Apps do not implement busy flags, callback queues, readiness
timers, or figure close guards.

Use direct `Bind="project...."` or `Bind="session...."` paths for ordinary
fields, ranges, sliders, file sources, and selection. Bound controls need no
callback or presenter operation unless the App has additional derived meaning.

## Portable Sources And Session Reconstruction

`labkit.app.layout.fileList` owns file/folder selection, portable source
records, removal, clearing, and optional selection binding:

```matlab
labkit.app.layout.fileList("sources", ...
    Filters=["*.csv", "CSV files"], ...
    Bind="project.inputs.sources", ...
    SelectionBind="session.selection.sources", ...
    SourceRole="measurement", ...
    SourceIdPrefix="source")
```

The App does not mirror those UI lifecycle actions with callbacks. Runtime
updates the bound source records and invokes `CreateSession` after source
changes:

```matlab
function session = createSession(project, callbackContext)
paths = callbackContext.resolveSourcePaths(project.inputs.sources);
session = struct("measurements", example.sourceFiles.read(paths));
end
```

Portable source records are opaque. Resolve their paths only at IO boundaries.
Saved projects store portable references and use runtime relinking.

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
specs own editable gestures and event-scoped resources.

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
operations for dialogs, status and diagnostics, portable sources, project
documents, result packages, render surfaces, and managed resources. It does
not expose figures, component registries, queues, lifecycle handles, or a
nested service bag.

Use context methods only at a callback or reconstruction boundary. Pure
readers, calculations, result builders, and render-model builders accept
ordinary explicit values.

An App-specific project button may choose a MAT file and return
`callbackContext.restoreProjectDocument(filepath)`. The context prepares the
same migrated, relinked project/session candidate used by the framework Load
State menu; the active callback transaction still owns validation, native
presentation, rollback, document metadata, and title publication.

## Persistence, Results, And Cleanup

`labkit.app.project.Schema` owns current project creation, validation, and
ordered version migration. Runtime owns the project envelope, atomic save,
restore, recovery, and relinking loop.

`labkit.app.result.File` and `labkit.app.result.Package` describe App-owned
outputs. `CallbackContext.writeResultPackage` writes through the runtime so
source and project provenance remain consistent.

Resources have event, interaction, document, or application scope. Replacing
the same scope and ID is idempotent; the runtime cleans every surviving
resource on scope end or close.

## Validation

Use focused contract tests for Definition, layout, callbacks, snapshots,
project schema, and runtime transactions. Add downstream App tests for changed
behavior and a bounded hidden-GUI test for native wiring. Automated hidden GUI
tests do not prove dialog quality, pointer feel, scientific validity, or a
complete interactive workflow.

See [Testing](../../development/maintain-and-release/testing.md) and
[Build A Complete App](../../development/build-apps/complete-app.md).
