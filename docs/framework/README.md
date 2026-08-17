# LabKit App SDK

`labkit.app` is the MATLAB App SDK above LabKit's GUI-free domain libraries.
Apps own scientific workflow, calculations, units, wording, plots, and exports.
The SDK owns semantic layout, transactions, project documents, portable
sources, dialogs, resources, results, and native component lifecycle.

## Start Here

| Goal | Documentation |
| --- | --- |
| Build or refactor an App | [Build a Complete App](../development/build-apps/complete-app.md) |
| Understand ownership boundaries | [Architecture](../development/build-apps/architecture.md) |
| Declare compatible LabKit modules | [Compatibility contracts](compatibility/contracts.md) |
| Look up exact MATLAB syntax | [Public API reference](../reference/README.md) |
| Browse the App SDK API by capability | [App SDK API](app-sdk-api.md) |
| Validate framework or GUI changes | [Testing](../development/maintain-and-release/testing.md) |

## SDK Map

The required path has three concepts:

| API | Purpose |
| --- | --- |
| `labkit.app.Definition` | App identity, lifecycle callbacks, layout, and launch |
| `labkit.app.layout.*` | Semantic inputs, displays, containers, and workbench structure |
| `labkit.app.view.Snapshot` | Derived visible state and App-owned rendering |

Read an App in this order: `definition.m` shows its complete contract,
`+workbench/buildLayout.m` shows the user workflow, and its capability
packages show the controls, state transitions, presentation, and rendering
owned by each feature. Open `projectSpec.m` or `createSession.m` only when the
definition names those optional capabilities.

Layout controls bind directly to named App callbacks, and plot areas bind
directly to their renderer. Apps do not maintain handler, renderer, or
capability registries. Runtime-injected values are
`labkit.app.CallbackContext` and typed `labkit.app.event.*` payloads.
Callbacks name those boundary values explicitly and delegate domain work
through narrow inputs.

Optional capabilities are grouped by purpose:

| Package | Purpose |
| --- | --- |
| `labkit.app.event.*` | Typed callback payloads |
| `labkit.app.interaction.*` | Managed plot gestures with direct callbacks |
| `labkit.app.plot.*` | Domain-neutral axes redraw, message, fit, and annotation mechanics |
| `labkit.app.project.*` | Durable project schema and migration |
| `labkit.app.result.*` | Exported files and result packages |
| `labkit.app.dialog.*` | Explicit dialog outcomes |
| `labkit.app.CallbackContext` | Runtime operations available inside callbacks |

## Smallest App

```matlab
function app = definition()
    workbench = labkit.app.layout.workbench({ ...
        labkit.app.layout.field("gain", Label="Gain", ...
            Kind="numeric", Bind="project.parameters.gain"), ...
        labkit.app.layout.button("run", "Run", @runAnalysis, ...
            Tooltip="Compute the result from the current gain.")});
    app = labkit.app.Definition( ...
        Entrypoint="labkit_Example_app", AppId="example", ...
        Title="Example", Family="Examples", ...
        AppVersion="1.0.0", Updated="2026-07-19", ...
        Requirements=labkit.contract.requirements("app", ">=2 <3"), ...
        Workbench=workbench);
end
```

The entrypoint calls `definition().launch(...)`. Definition compiles the
immutable semantic graph before creating a figure, validates direct callback
and renderer signatures, and builds one private native platform plan.

## Paved Road

- Bind ordinary state with `Bind="project..."` or `Bind="session..."`.
- Keep ordinary actions on the framework's consistent single-line native
  button rhythm. A readonly `field` automatically wraps its current text and
  adjusts to the available width; Apps do not declare line counts or a separate
  message type. Dividers belong between resizable sections, not after the final
  section.
- Give every editable semantic surface one declared behavior owner before
  launch: editable fields, ranges, and sliders use `Bind` or
  `OnValueChanged`; file lists require `Bind`; plot view modes require
  `OnValueChanged`; and editable table columns require `OnCellEdited`.
  Workspace page callbacks require named pages. Binding and callback changes
  use the same validation and rollback behavior.
- Use `labkit.app.layout.fileList` for portable file records and selection.
  Multi-file collections use native multi-selection; a semantic single-file
  slot declares `MaxFiles=1` and single selection. File buttons describe only
  files because folder and recursive-tree acquisition have separate controls.
  Set `AllowDuplicatePaths=true` only when separate workflow tasks may share
  one resolved path, and present row-level workflow state with
  `Snapshot.fileItemStatuses`.
  For content formats that cannot be distinguished by filename extension,
  declare a pure batch `PathFilter` and a reader-facing
  `PathFilterDescription`. The runtime applies the predicate only to newly
  proposed files, omits rejected paths before source records are created, and
  reports aggregate kept/filtered counts without exposing filenames.
  Unhandled validation or parsing failures from file-panel actions roll back
  transactionally and appear in an alert rather than only in callback output.
  Source changes rebuild the transient session; Apps do not mirror choose,
  remove, clear, or selection UI events.
- Give every scientific or workflow action an App-owned `Tooltip`. The
  framework guarantees a nonempty label-based fallback, while repository
  guardrails require tracked Apps to explain the action instead of repeating
  its visible label. File-list choose/folder/remove/clear controls expose
  dedicated tooltip options and domain-neutral label defaults.
- Give a potentially long action a concise App-owned `BusyMessage`. Runtime
  rejects reentrant input as soon as the action starts, but delays visible
  busy feedback briefly so quick actions do not flash the pointer, title, or
  disabled controls. If work outlives that delay, Runtime freezes mutable
  controls and shows the busy stage until the latest committed view is
  restored. User-facing `info`, `warning`, or failure logs emitted during the
  action update the visible stage; Apps do not create progress windows.
- Rebuild transient data with
  `session = createSession(project,context)` and resolve opaque source records
  with `context.resolveSourcePaths`.
- Use `context.postEvent(eventId,updateState)` when a timer, device driver,
  network stream, monitor, or dashboard needs to publish fresh App state.
  Runtime coalesces pending posts with the same semantic ID, runs the latest
  update as a normal validated transaction after any active transaction has
  completed, and ignores posts after close. Posted stream refreshes do not
  activate the user-action busy pointer or disable controls.
- Return only derived view state from `labkit.app.view.Snapshot`; runtime
  supplies layout defaults, bindings, file state, log text, and status text.
- Give short `statusPanel` summaries an explicit `Lines` hint so the native
  layout reserves detail height only for genuinely multiline content.
- Use `labkit.app.layout.dataTable` with
  `labkit.app.event.TableCellEdit` and
  `labkit.app.event.TableCellSelection`; Apps never decode native events.
- Use `labkit.app.layout.plotArea` and a fixed
  `renderer(axesById,model)` callback. `axesById` is always a named struct,
  even when the plot area declares only one axis.
- Pass a transient `ViewRevision` to `Snapshot.renderPlot` when an App exposes
  an explicit reset-view action. The adapter preserves user zoom while the
  revision is unchanged and accepts renderer-fitted limits once when it
  changes.
- Pass one workspace node or a row cell array of vertically arranged nodes to
  `workspace.page`; growable tables and plots share the available page height
  without an App-authored wrapper section.
- Use `layout.group(..., Title="...")` for a nested reader-facing control
  boundary inside a section; leave `Title` blank for arrangement-only groups.
- A control tab containing one growable file list, table, log, status, or
  plot surface fills the available tab height. Tabs with longer mixed content
  remain scrollable.
- Declare editable overlays with `labkit.app.interaction.*` on the plot area;
  supply their current values with same-named Snapshot methods.
- Open `anchorPath` editors order a new point by the nearest location on the
  visible path: points beyond the start prepend, points beyond the end append,
  and interior points insert into the owning curve segment. Zoom does not
  change that ordering decision.
- For a managed rectangle with `OnBackgroundPressed`, an un-dragged click
  anywhere on its plot—including inside the rectangle—uses that point
  callback; dragging the rectangle still uses its change callback.
- Use `labkit.app.plot.clearAxes`, `showMessage`, and `fitAxesToGraphics`
  for renderer mechanics; `EqualDataUnits=true` makes a one-time fitted
  equal-scale view from the settled native axes allocation without dispatching
  pending UI callbacks, without changing the allocation or locking later zoom.
  Apps still decide message wording and viewport policy.
- Use `labkit.app.project.Schema`, `labkit.app.result.File`, and
  `labkit.app.result.Package` only when those optional capabilities exist.
- Use `labkit.app.project.sourceRecord` only in pure project creation or
  migration code that must turn a legacy path into a portable source value;
  runtime callbacks still resolve paths through `CallbackContext`.

Runtime validates candidate state and the complete view snapshot before
publishing either. The private MATLAB adapter maps semantic IDs to native
components, skips unchanged native property writes, reuses direct associations
between controls and their labels, preserves plot viewports, normalizes native
event differences, and never exposes component registries to Apps.

Normal App launches show the completed native window. Official GUI validation
uses the same launch path with a framework-owned visibility policy: `hidden`
keeps the final window off screen and `minimized` minimizes it after startup.
Tests therefore exercise real controls without individual Apps or test methods
having to hide the window after launch.

## Built-in App Tools

The native runtime installs one top-level **Tools** menu so framework-owned
utilities do not compete with the App's workflow controls:

- **Plots** opens, copies, or saves the App's plot surfaces.
- **Screenshot** copies the complete App surface to the system clipboard or
  writes a uniquely named PNG beneath `artifacts/screenshots/`. A save dialog
  is used only if automatic artifact output fails.
- **Project State** writes a uniquely named project beneath
  `artifacts/states/` or loads a selected project when the App declares a
  project schema. A save dialog is used only if automatic output fails.
- **Diagnostics** opens the App-named Session Log or exports a uniquely named
  bundle beneath `artifacts/diagnostics/`. Every export contains complete
  sensitive messages, attributes, exception text, stack locations, and App
  state. The exact option writes `app-state.mat`; the compact option writes
  `app-state-compact.mat` after replacing supported state leaves larger than
  1 MiB with same-class, same-dimension, compressible synthetic placeholders.
  `bundle-report.json` records every replacement without storing its value.
  Compact is the default; exact remains an explicit choice. After the first
  ERROR or CRITICAL event, closing the App automatically writes a compact
  diagnostic bundle. Selecting an event highlights its complete table row.
  Text fallback retains complete events and reports that the selected MAT
  state could not be represented as text.

These actions are framework-owned native behavior. Apps do not declare menu
items, implement clipboard integration, or duplicate project persistence
callbacks.

App callbacks use `CallbackContext.inform` for successful or neutral
information and reserve `CallbackContext.alert` for blocking problems. The two
capabilities map explicitly to native information and error icons.

Framework concepts and source names are versionless. Compatibility belongs to
`labkit.app.version`; saved-data versions belong to
`labkit.app.project.Schema`.

Project persistence is optional. An App that declares no `ProjectSchema` can
keep an entire live monitor or replay workflow in transient `session` state
and managed resources. Runtime marks a document changed only when the
validated `project` value actually changes; session-only refreshes do not
create false unsaved-change state.

## Related Topics

- [App catalog](../apps/README.md)
- [App development](../development/build-apps/app-development.md)
- [Project history](../history/README.md)
