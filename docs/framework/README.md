# LabKit App Framework

`labkit.ui` is the MATLAB App SDK above LabKit's GUI-free domain libraries.
Apps own scientific workflow, calculations, units, wording, plots, and
exports. The framework owns semantic component construction, transactions,
project documents, portable sources, dialogs, resources, results, and native
component lifecycle.

## Start Here

| Goal | Documentation |
| --- | --- |
| Build or refactor an App | [Build a Complete App](../development/build-apps/complete-app.md) |
| Understand ownership boundaries | [Architecture](../development/build-apps/architecture.md) |
| Declare compatible LabKit modules | [Compatibility contracts](compatibility/contracts.md) |
| Look up exact MATLAB syntax | [Public API reference](../reference/README.md) |
| Validate framework or GUI changes | [Testing](../development/maintain-and-release/testing.md) |

## Authoring Model

An App definition returns one validated `labkit.ui.Application`:

```matlab
function app = definition()
    run = labkit.ui.Command("run", @runAnalysis);
    layout = labkit.ui.Layout.workbench({ ...
        labkit.ui.Layout.field("gain", Label="Gain", ...
            Kind="numeric", Bind="project.parameters.gain"), ...
        labkit.ui.Layout.action("run", "Run", run)});
    app = labkit.ui.Application( ...
        Command="labkit_Example_app", Id="example", ...
        Title="Example", Family="Examples", ...
        AppVersion="1.0.0", Updated="2026-07-19", ...
        Requirements=labkit.contract.requirements("ui", ">=8 <9"), ...
        Project=example.projectSpec(), Layout=layout);
end
```

The entrypoint constructs that value and calls `launch`:

```matlab
function varargout = labkit_Example_app(varargin)
    app = example.definition();
    [varargout{1:nargout}] = app.launch(varargin{:});
end
```

`Application` compiles the immutable Layout graph before creating a figure.
It collects Commands referenced by Layout, validates callback roles and
renderer references, and builds one private native platform plan. Apps do not
register the same Command again, receive component registries, or manipulate
framework lifecycle state.

## Paved Road

- Bind ordinary state directly with `Bind="project..."` or
  `Bind="session..."`; no callback or presenter operation is needed.
- A standard `filePanel` owns portable records, add/remove/clear, selection,
  and transient session rebuild. App code declares `Bind` and
  `SelectionBind`.
- `Session` has one fixed shape:
  `session = createSession(project,context)`. Resolve opaque source paths with
  `context.sourcePaths`.
- Runtime combines Layout defaults, bindings, framework-owned state, and the
  App's dynamic `Presentation` fragment into one complete snapshot.
- A renderer has the fixed shape `renderer(axes,model)`. For a multi-axis
  preview, `axes` follows the declared `AxisIds` order.
- Omit `Capabilities` on the ordinary path. An explicit allow-list is advanced
  audit metadata.
- Use `ProjectContract()` for a default version-1 scalar-struct project, or
  provide fixed create/validate/migrate callbacks for a domain schema.
- Use `ResultOutput` and `Result` for App-owned output meaning; runtime writes
  provenance, sizes, checksums, and the manifest.

## Transaction And Platform Boundary

Runtime validates candidate state and the complete presentation before
publishing either. A failed command, project restore, native component update,
or renderer restores the prior state and replays the prior native view.
Queued commands are FIFO and event-scoped resources are cleaned after success
or failure.

The MATLAB adapter is private. It maps semantic IDs to native components,
routes native callbacks only through typed runtime entrypoints, preserves
manual plot viewports, and never exposes a registry or general component
mutation API to Apps.

## Extension Gate

A new public UI capability needs evidence from at least two Apps or one
framework-owned lifecycle/consistency requirement. Repeated App callback or
presenter glue is evidence for framework automation; App-specific scientific
behavior remains in the owning App.

Framework concepts and source names are versionless. Compatibility belongs to
`labkit.ui.version` and App requirements; saved-data versions belong to
`ProjectContract`.

## Public API Documentation

Exact syntax, inputs, outputs, defaults, errors, examples, and related symbols
come from public MATLAB help. Browse the [API reference](../reference/README.md).

## Related Topics

- [App catalog](../apps/README.md)
- [App development](../development/build-apps/app-development.md)
- [Project history](../history/README.md)
