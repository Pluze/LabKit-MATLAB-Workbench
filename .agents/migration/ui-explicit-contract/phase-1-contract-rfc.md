# UI explicit-contract replacement RFC

Status: accepted for phased production implementation on 2026-07-19 after the
executable representation comparison. This is not yet a released API.

## Decision summary

The replacement uses a small set of sealed immutable value classes composed
through strict constructors. Role-specific callbacks are chosen over one
generic payload callback. Project and result coordination remain owned by
`labkit.ui` because they participate in runtime transactions, recovery,
source relinking, and App-scoped provenance; they do not justify a new public
`data`, `io`, or `util` facade.

The current runtime stays active until every App is migrated and the retired
surface can be deleted atomically. Prototype code lives only under
`tools/migration/` and must be deleted before Phase 8.

## Public vocabulary

The intended public concepts are deliberately fewer than the current struct
fields and service operations:

| Concept | Construction and readable surface | Purpose |
| --- | --- | --- |
| Application | `labkit.ui.application(...)` plus owned `command`, `renderer`, `start`, and `debugSample` composition | One validated App definition and product contract |
| Project contract | `labkit.ui.project(...)` | Payload creation, validation, migration, resume, relink, and named legacy import |
| Command | `labkit.ui.command(id, callback, Role=...)` | Declared callback role and stable reference |
| Layout | Existing semantic layout constructor names returning immutable values | Controls, sections, pages, workspace, and declarative signals |
| Workspace | `workspace(content)` or `workspace().page(...).initialPage(...)` | Single or multi-page right-side ownership |
| Presentation | `labkit.ui.presentation()` and role-specific operations | Deterministic target-checked visible state |
| Interactions | Named functions under `labkit.ui.interaction` | One value/signal contract per editor type |
| Runtime context | `labkit.ui.RuntimeContext` readable method surface | App-neutral dialogs, dispatch, workflow, sources, resources, persistence, and results |
| Result output/manifest | `labkit.ui.resultOutput(...)`, `labkit.ui.result(...)` | Validated output and provenance values |
| Named payload values | Table edit, selection, dialog result, and source selection | Multi-field signal results without generic event structs |

The aggregate classes are `Application`, `ProjectContract`, `Command`,
`Layout`, `Presentation`, `RuntimeContext`, `ResultOutput`, and `Result`.
Small payload classes are added only when a signal carries more than one
named value. Interaction functions return one internal immutable interaction
value; there is no public base-class hierarchy.

All properties are read-only. Apps construct and compose values but cannot
mutate or inspect a backing struct. Runtime compilation may convert validated
values to private structs.

## Application and project contract

Proposed definition:

```matlab
function app = definition()
    app = labkit.ui.application( ...
        Command="labkit_TTestWizard_app", ...
        Id="ttest_wizard", ...
        Title="T-Test Wizard", ...
        DisplayName="T-Test Wizard", ...
        Family="Statistics", ...
        AppVersion="1.0.0", ...
        Updated="2026-07-19", ...
        Requirements=labkit.contract.requirements("ui", ">=8 <9"), ...
        Project=ttest_wizard.projectContract(), ...
        Session=@ttest_wizard.createSession, ...
        Layout=@ttest_wizard.userInterface.layout, ...
        Present=@ttest_wizard.userInterface.present);
    app = app.commands(ttest_wizard.commands());
    app = app.renderer("resultPreview", ...
        @ttest_wizard.userInterface.drawResultPreview);
end
```

`application` rejects an unknown name, duplicate command or renderer, empty
required metadata, invalid version/date, unsupported requirement, callback
role mismatch, and missing referenced command/renderer before figure creation.
Static Apps omit commands, session, presenter, renderer, and startup work.

`project` accepts only named `Version`, `Create`, `Validate`, `Migrate`,
`CreateResume`, `ApplyResume`, `RelinkSources`, and `LegacyImport` operations.
Payload version is independent of the `labkit.ui` facade range. Existing valid
payloads and legacy imports retain their current meaning.

## Commands, signals, and payloads

Role-specific signatures are fixed:

| Role | Signature |
| --- | --- |
| Invoke/start | `state = callback(state, context)` |
| Scalar value | `state = callback(state, value, context)` |
| Table edit | `state = callback(state, edit, context)` |
| Selection | `state = callback(state, selection, context)` |
| Interaction | `state = callback(state, value, context)` where the named interaction documents `value` |

`TableEdit` exposes row ID/index, column ID/index, previous value, and new
value. `Selection` exposes stable item IDs/indices. Dialog results expose
`Cancelled` and the typed chosen value. No callback receives an open event,
`meta`, registry, source handle, or raw MATLAB event.

Layout signals bind directly to a `Command` value or a command ID resolved
during compilation. Callback role is declared by the originating control and
must match the command. Construction uses MATLAB's read-only `nargin(handle)`
and `nargout(handle)` definition queries to require the role's one fixed input
and output shape; variable-arity handles are rejected. Runtime dispatch does
not inspect arity, retry after an exception, or guess an alternate shape.

Programmatic dispatch receives a compiled command reference and its declared
payload. FIFO order, whole-state validation, presentation transaction,
rollback, diagnostics, and event-scope cleanup remain required.

## Layout and workspace

The audited constructors remain stable semantic concepts:

`action`, `field`, `filePanel`, `group`, `logPanel`, `panner`, `previewArea`,
`rangeField`, `resultTable`, `section`, `statusPanel`, `tab`, `workbench`, and
`workspace`.

Each has an `arguments`-checked complete option set; unknown spelling and an
option irrelevant to the chosen control kind fail at construction. Layout
values own one parent. Compilation checks global IDs, legal nesting, command
roles, bindings, renderer references, initial values, choices/limits, and
workspace page references without creating a figure.

Workspace shapes:

```matlab
workspace = labkit.ui.layout.workspace(content);

workspace = labkit.ui.layout.workspace();
workspace = workspace.page("data", "Data", dataContent);
workspace = workspace.page("plot", "Plot", plotContent, ...
    AvailableWhen="session.hasResult");
workspace = workspace.initialPage("data");
```

`workspace` owns `page`; no parallel global page constructor is introduced.
Concrete grids, rows, columns, tabs, panels, pixels, and registry paths are
private platform-adapter choices.

## Presentation

Presentation is a value with a closed operation set:

```matlab
view = labkit.ui.presentation();
view = view.value("worksheet", state.session.sheet);
view = view.choices("group", state.session.groupNames);
view = view.limits("gain", [0 10]);
view = view.enabled("runTest", state.session.canRun);
view = view.visible("status", state.session.showStatus);
view = view.text("status", state.session.statusText);
view = view.files("sources", state.project.inputs.sources);
view = view.selection("sources", state.session.selection.sourceIds);
view = view.table("dataTable", state.session.tableModel);
view = view.plot("resultPlot", "groupComparison", state.session.plotModel);
view = view.workspacePage("plot", Enabled=state.session.hasResult, ...
    Status=state.session.plotStatus);
view = view.interaction(scale);
```

There is no generic `set(target, property, value)`. Compilation resolves each
target and static capability. Commit validates dynamic type/range/model values
before applying any operation, then applies the complete presentation
transaction. Unknown targets, unsupported operations, renderers, axes, or
workspace pages fail without a partial view. Renderers receive platform-owned
axes and the declared App model. A plot placeholder/stale status is explicit.

## Interactions

The seven audited interaction contracts become named strict functions:

- `anchorPath`
- `pairedAnchors`
- `pointSlots`
- `rectangle`
- `regionSelection`
- `interval`
- `scaleReference`

Each declares target, value, limits, change command, commit policy, viewport
policy, and its small closed visual option set. `scaleReference` owns scale
points/calibration/bar editing as one lifecycle. Unknown style names fail.
Editable overlays are runtime-owned resources; renderer graphics are
display-only with hit testing disabled.

There is no public `Kind`, `Targets`, `Value`, `Event`, `Options`,
`BackgroundEvent`, `ScrollEvent`, or `ChangePolicy` transport object.

## Runtime context

The context has discoverable direct methods grouped by ownership, not nested
open structs:

- `dispatch`, `appendStatus`, and `reportError`;
- `alert`, `choose`, `chooseInputFile`, `chooseInputFolder`,
  `chooseOutputFile`, and `chooseOutputFolder`;
- `saveProject`, `saveRecovery`, `sourceRecord`, `upsertSource`, and
  `reconcileSources`;
- `previewTarget` for a declared advanced target only;
- `setResource`, `getResource`, `removeResource`, and `clearResourceScope`;
- `writeResult`.

The runtime constructs the concrete context; tests construct a contract-equal
test context. It never exposes figure, debug object, launch request, registry,
component handle, or arbitrary test-only field. File/dialog cancellation is a
normal typed result. Resource scopes are `event`, `interaction`, `document`,
and `application`; replacement and scope end dispose exactly once.

## Results

`resultOutput` requires ID, role, relative path, media type, and status.
Optional message/warnings are typed text. `result` requires outputs, inputs,
parameters, and summary; provenance, platform, App/facade versions, project
document/revision, checksums, and creation IDs/times are runtime-owned.

An extension requires an explicitly named namespace and schema version.
Unknown fields, duplicate output IDs/paths, escaping paths, absent successful
outputs, invalid media type/status, or manifest/output mismatch fail before
the existing manifest is replaced.

## Errors, cancellation, and recovery

Stable public groups:

- `labkit:ui:contract:UnknownArgument`
- `labkit:ui:contract:InvalidValue`
- `labkit:ui:contract:DuplicateId`
- `labkit:ui:contract:UnknownReference`
- `labkit:ui:contract:CallbackRoleMismatch`
- `labkit:ui:contract:UnsupportedOperation`
- `labkit:ui:runtime:ActionFailed`
- `labkit:ui:runtime:InvariantFailure`

Messages include the public symbol/parameter/ID. Optional absence selects a
documented default; a supplied malformed value never does. Native exceptions
may be wrapped only with the public operation and original cause preserved.
Action failure restores prior state and presentation and reports diagnostics.
Valid saved payloads are not rewritten merely because this UI boundary
changes.

## Ownership and lifecycle

```text
Application value
  +-- Project contract
  +-- Commands and renderers
  `-- Immutable layout
        `-- owned targets/signals
                 |
                 v
          compiled private plan
                 |
                 v
Application runtime context
  +-- document/project scope
  +-- interaction scopes
  +-- event scope
  `-- private MATLAB UI adapter
```

Scope teardown is inside-out. Replacing a resource disposes the prior value;
event completion/failure clears event scope; interaction removal clears its
scope; document replacement clears document scope; figure/application close
clears everything once.

## Source compatibility

Within one compatible `labkit.ui` major range, valid constructors, callback
roles, defaults, payload fields, ownership, and error groups retain meaning.
Additions are optional. Breaking changes require the next major facade range.
Saved App payload versions remain governed by each App project contract.

The migration is source-breaking once, with analyzer diagnostics and codemod
help but no production translation layer, alias table, dual runtime, hidden
fallback, or version-named namespace. The released boundary changes only after
all 21 Apps compile and pass their focused tests.

## Representation comparison gate

Executable disposable prototypes must compare this value-class form with
opaque strict function values for T-Test Wizard, Curvature Measurement, and
Video Marker. Measure:

- public concepts and source lines at framework seams;
- help/introspection discoverability;
- unknown argument/target/signal/interaction failures;
- GUI-free deterministic presentation;
- callback-role validation before launch;
- ability to prevent App mutation/inspection of backing representation;
- Phase 0 performance thresholds.

The accepted representation is the sealed immutable value-class form. The
prototype evidence is complete, and the repository owner delegated the
architecture choice after reviewing the small value-class versus opaque-value
comparison. Production implementation may proceed through the Phase 2 gates;
this approval does not authorize a mutable handle model or public inheritance
hierarchy.
