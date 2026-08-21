# LabKit App SDK

`labkit.app` is the MATLAB App SDK above LabKit's GUI-free domain libraries.
Apps own scientific workflow, calculations, units, wording, plots, and exports.
The SDK owns semantic layout, transactions, execution queues, lifecycle,
runtime source lists, diagnostics, dialogs, resources, and native components.

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
owned by each feature. App-specific state construction and reconstruction stay
inside that App.

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
| `labkit.app.source.*` | Live file-list source values |
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
        Workbench=workbench);
end
```

The entrypoint calls `definition().launch(...)`. Definition compiles the
immutable semantic graph, validates direct callback and renderer signatures,
and checks every declared LabKit facade version before creating a figure and
building one private native platform plan.

## Paved Road

- Bind controls to dotted paths in the App's own in-memory state. The SDK does
  not reserve root field names or define a project/session schema.
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
- Use `labkit.app.layout.fileList` for live file records and selection.
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
  Source changes invoke the App's optional state refresh; Apps do not mirror
  choose, remove, clear, or selection UI events.
- Give every scientific or workflow action an App-owned `Tooltip`. The
  framework guarantees a nonempty label-based fallback, while repository
  guardrails require tracked Apps to explain the action instead of repeating
  its visible label. Auxiliary file-list buttons derive hover text from their
  visible labels.
- Give a potentially long action a concise App-owned `BusyMessage`. Runtime
  rejects reentrant action input as soon as the action starts, but delays
  visible busy feedback briefly so quick actions do not flash the pointer,
  title, or disabled controls. If work outlives that delay, Runtime freezes
  mutable leaf inputs while leaving tabs, panels, plots, and the last committed
  view visible until the next view is ready. Slider changes and managed plot
  gestures are direct manipulation transactions: they remain serialized but
  do not show action-style busy feedback. User-facing `info`, `warning`, or
  failure logs emitted during an action update the visible stage; Apps do not
  create progress windows.
- Rebuild transient data in `RefreshState` and read source paths with
  `labkit.app.source.paths`.
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
- Write App result files directly through the App-owned export capability.
  Any manifest or task archive is an App contract, not an SDK object.

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
- **Diagnostics** opens the App-named Session Log or exports a uniquely named
  bundle beneath `artifacts/diagnostics/`. Every export contains complete
  sensitive messages, attributes, exception text, stack locations, and App
  state. It writes `app-state-compact.mat` after replacing supported state leaves larger than
  1 MiB with same-class, same-dimension, compressible synthetic placeholders.
  `bundle-report.json` records every replacement without storing its value.
  After the first ERROR or CRITICAL event, closing the App automatically writes a
  diagnostic bundle. Selecting an event highlights its complete table row.
  Text fallback retains complete events and reports that the compact MAT
  state could not be represented as text.
  **Export Previous Active Session** writes a read-only bundle for the newest
  same-App journal that was left active, such as after a MATLAB hang or
  abnormal termination.

The SDK has no task archive, save/load callbacks, dirty tracking, recovery
files, or generic continuation workflow. Apps that genuinely support pausing
and continuing work own explicit controls and their complete JSON, CSV, or MAT
snapshot format.

Each App session keeps its persistent structured journal beneath
`artifacts/logs/sessions/` in the active LabKit installation. LabKit does not
automatically migrate or delete journals from this folder; users can inspect,
archive, or remove generated artifacts with ordinary filesystem tools. Releases
that previously wrote session journals beneath MATLAB's `prefdir/LabKit/logs/`
leave those existing files unchanged. The journal subsystem does not inspect or
prune other sessions in the background.

Before Runtime enters an App callback it durably closes and reopens the active
journal segment after writing the root operation start. State-update and
validation stages stay in the buffered event stream; immediately before native
presentation, Runtime writes those stages plus a durable presentation-entry
checkpoint. If
MATLAB hangs, the newest operation without a terminal event identifies the
last entered stage on the next launch.

These actions are framework-owned native behavior. Apps do not declare menu
items or implement clipboard and diagnostic integration.

App callbacks use `CallbackContext.inform` for successful or neutral
information and reserve `CallbackContext.alert` for blocking problems. The two
capabilities map explicitly to native information and error icons.

Framework concepts and source names are versionless. Compatibility belongs to
`labkit.app.version`; any task-archive version belongs to the App that defines
that archive. Runtime has no project document identity or dirty state.

## Related Topics

- [App catalog](../apps/README.md)
- [App development](../development/build-apps/app-development.md)
- [Project history](../history/README.md)
