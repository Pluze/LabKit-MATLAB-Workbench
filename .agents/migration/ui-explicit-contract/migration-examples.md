# App SDK explicit-contract migration examples

These examples are source-edit guidance for the accepted RFC. They are not a
runtime adapter and do not make generated edits scientifically correct.

## Definition

Before:

```matlab
def = labkit.ui.runtime.define( ...
    "Id", "example", ...
    "Project", projectSpec(), ...
    "Actions", struct("run", @onRun), ...
    "Renderers", struct("preview", @drawPreview), ...
    "Layout", @buildLayout, ...
    "Present", @present);
```

After:

```matlab
run = labkit.app.StateHandler("run", @onRun);
layout = labkit.app.layout.workbench({ ...
    labkit.app.layout.button("run", "Run", run)}, ...
    Workspace=labkit.app.layout.workspace( ...
        labkit.app.layout.plotArea( ...
            "preview", Renderers="preview")));
app = labkit.app.Definition( ...
    Entrypoint="labkit_Example_app", AppId="example", ...
    Title="Example", Family="Examples", AppVersion="1.0.0", ...
    Updated="2026-07-19", ...
    Requirements=labkit.contract.requirements("app", ">=1 <2"), ...
    ProjectSchema=projectSpec(), Workbench=layout, BuildView=@present, ...
    Renderers=struct("preview", @drawPreview));
```

Layout signals are collected automatically; no duplicate StateHandler registry is
maintained by the App.

## View snapshot

Before:

```matlab
view.controls.run = struct("Enabled", state.session.canRun);
view.controls.status = struct("Text", state.session.status);
view.previews.image = struct( ...
    "Renderer", "preview", "Model", state.session.preview);
```

After:

```matlab
view = labkit.app.view.Snapshot();
view = view.enabled("run", state.session.canRun);
view = view.text("status", state.session.status);
view = view.renderPlot("image", "preview", state.session.preview);
```

## Interaction

Before:

```matlab
view.interactions.roi = struct( ...
    "Kind", "rectangle", ...
    "Targets", "image", ...
    "Value", state.session.roi, ...
    "Event", "roiChanged", ...
    "Options", struct("color", [1 1 1]));
```

Accepted semantic target (not production syntax until Phase 4 closes):

```matlab
roi = labkit.app.interaction.rectangle( ...
    Target="image", ...
    Bounds=state.session.roi, ...
    Changed=commands.roiChanged, ...
    Color=[1 1 1]);
view = view.interaction(roi);
```

The interaction example remains deliberately labelled as a target because the
production interaction constructors and `view.Snapshot.interaction` operation
are not implemented yet. It must become an executable example when Phase 4
closes; it is not currently an API promise.

## Callback and context

Before:

```matlab
function state = onFilesSelected(state, event, services)
    indices = services.events.indices( ...
        event, "selectedFiles", numel(state.project.inputs.sources));
    state.session.selection.files = indices;
    state = services.workflow.log(state, "Selection changed.");
end
```

After:

```matlab
function state = onFilesSelected(state, selection, context)
    state.session.selection.files = selection.Indices;
    context.appendStatus("Selection changed.");
end
```

The handler is declared with `Event="listSelection"`, so compilation validates this
signature and the originating control before figure creation.

## Review rule

Mechanical edits may replace exact constructor or operation spelling only
after the production vocabulary is approved. A reviewer still verifies App
state ownership, handler event, payload meaning, project compatibility,
scientific results, cancellation, cleanup, and focused GUI behavior. No
analyzer output is accepted as semantic proof.
