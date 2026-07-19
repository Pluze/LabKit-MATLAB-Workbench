# UI explicit-contract migration examples

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
app = labkit.ui.application( ...
    Id="example", ...
    Project=projectContract(), ...
    Layout=@buildLayout, ...
    Present=@present);
app = app.command(labkit.ui.command("run", @onRun, Role="invoke"));
app = app.renderer("preview", @drawPreview);
```

The complete product metadata remains explicit; it is omitted here only to
keep the seam comparison readable.

## Presentation

Before:

```matlab
view.controls.run = struct("Enabled", state.session.canRun);
view.controls.status = struct("Text", state.session.status);
view.previews.image = struct( ...
    "Renderer", "preview", "Model", state.session.preview);
```

After:

```matlab
view = labkit.ui.presentation();
view = view.enabled("run", state.session.canRun);
view = view.text("status", state.session.status);
view = view.plot("image", "preview", state.session.preview);
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

After:

```matlab
roi = labkit.ui.interaction.rectangle( ...
    Target="image", ...
    Bounds=state.session.roi, ...
    Changed=commands.roiChanged, ...
    Color=[1 1 1]);
view = view.interaction(roi);
```

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
    state = context.appendStatus(state, "Selection changed.");
end
```

The command is declared with `Role="selection"`, so compilation validates this
signature and the originating control before figure creation.

## Review rule

Mechanical edits may replace exact constructor or operation spelling only
after the production vocabulary is approved. A reviewer still verifies App
state ownership, callback role, payload meaning, project compatibility,
scientific results, cancellation, cleanup, and focused GUI behavior. No
analyzer output is accepted as semantic proof.
