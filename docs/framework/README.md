# LabKit App Framework

`labkit.ui` is the application framework above the domain libraries and
concrete apps. It provides lifecycle management, semantic workbench layouts,
action dispatch, project save/load support, presentation updates, managed
interactions, debug traces, and top-level utilities. App packages supply the
workflow decisions, scientific calculations, data schemas, labels, and exports.

## Start Here

| Goal | Documentation |
| --- | --- |
| Understand how an App starts and processes actions | [Runtime and lifecycle](runtime.md) |
| Build or refactor a concrete App | [App development](../development/app-development.md) |
| Choose reusable package boundaries | [Architecture](../development/architecture.md) |
| Look up exact MATLAB function syntax | [Public API reference](../libraries/README.md) |
| Validate framework or GUI changes | [Testing](../development/testing.md) |

## Module Overview

| Package | Responsibility | Typical entry points |
| --- | --- | --- |
| `labkit.ui.runtime` | Launch, lifecycle, queued actions, canonical state, persistence, dialogs, resources | `launch`, `define`, `saveState`, `loadState` |
| `labkit.ui.layout` | Data-only semantic workbench descriptions | `workbench`, `tab`, `section`, `filePanel`, `previewArea`, `action` |
| `labkit.ui.plot` | Viewport-safe plot and image mechanics | `clear`, `fit`, `fitCanvas`, `message`, `clampData` |
| `labkit.ui.interaction` | Managed axes interactions and reusable geometry | `enablePopout`, `anchorPath`, `scaleBarGeometry` |
| `labkit.ui.debug` | Structured trace and exception context | `context` |

This package division is the supported public surface. Primitive MATLAB UI
handles, registry mutation, concrete grid geometry, event queues, renderer
internals, and resource cleanup implementations stay private.

## Runtime Model

An App declares a definition and passes it to `labkit.ui.runtime.launch`:

```matlab
function varargout = labkit_Example_app(varargin)
    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @example.definition, varargin{:});
end
```

A static App package needs only that thin entrypoint, one `definition.m`, and
its semantic layout. The definition is the single product contract: it owns
the command, stable ID, names, family, App version, update date, LabKit
requirements, layout, and any optional capabilities. The runtime supplies an
empty version-1 project, empty session, no actions, and an empty presentation
model until the App opts into more behavior.

The framework then validates the definition, creates canonical project and
session state, builds the semantic layout, generates callbacks, commits the
first presentation, and queues the optional start action. App handlers receive
semantic events plus injected services and return updated state. They do not
own busy flags, callback plumbing, persistence envelopes, or UI resource
lifetimes. Project loading resolves portable external sources before session
creation; when a required source moved, the framework identifies it and lets
the user locate a replacement without committing a partial project. Migrated
or relinked documents remain visibly unsaved until **Save State** atomically
writes the current project format. Each project, explicit autosave, and
recovery write recalculates source-relative paths from that MAT file's actual
destination, so moving a saved project tree does not depend on the folder from
which the source was first imported.

Variable-length sources and manifest outputs start from framework-provided
empty arrays (`emptySourceRecords` and `services.results.emptyOutputs()`),
then append validated real records. Apps do not construct empty-ID placeholder
records merely to copy their struct shape. App code reads current source
locations through `labkit.ui.runtime.sourcePaths` rather than depending on the
runtime-owned portable-reference fields.

A persistent App exposes one `projectSpec.m` entry containing its project
version plus local create, validate, and migrate functions. Runtime V2 owns the
loop across missing versions and validates each returned payload; App packages
do not publish one migration file per historical step.

Read [Runtime and lifecycle](runtime.md) for the detailed definition fields,
state transaction rules, startup/readiness behavior, plot and interaction
contracts, debug semantics, callback policy, and the responsibilities of the
framework and app.

## Public API Documentation

Exact syntax, inputs, outputs, defaults, legal values, examples, and related
functions are generated from the help block immediately following each public
function declaration. Open the [API reference](../libraries/README.md) and
search for a fully qualified symbol such as `labkit.ui.runtime.launch`.

## Related Topics

- [App catalog](../apps/README.md)
- [App development](../development/app-development.md)
- [Architecture](../development/architecture.md)
- [Project history](../history/README.md)
