# Migration Debt Ledger

This file records only active architecture migration or compatibility-retirement
debt. Current supported behavior belongs in `docs/`; execution rules belong in
the nearest `AGENTS.md`; exact validation commands belong in
`docs/development/maintain-and-release/testing.md`; completed work belongs in
component history.

## Active debt

Last audited: 2026-07-19.

```text
toolbox-product-debt: none
app-sdk-migration-debt: ui-explicit-contract-redesign
```

## App SDK explicit-contract migration

### Decision and scope

- **Debt ID:** `ui-explicit-contract-redesign`
- **Owner:** `labkit.app`
- **Target boundary:** stable `labkit.app` 1.x and every tracked App currently
  consuming legacy `labkit.ui`
- **Status:** Phase 0 inventory, Phase 1 contract gates, and Phase 2 strict
  kernel complete; Phase 3 runtime/platform implementation and App migration
  in progress
- **User-visible reason:** App authors must be able to discover the framework
  from function, constructor, method, and parameter names. Invalid App code
  must fail at the contract boundary instead of being ignored, guessed, or
  rendered in an unintended form.
- **Release model:** a deliberate incompatible-contract replacement, not an
  additive compatibility layer on the current runtime

### User-visible UI parity audit

The 2026-07-19 `main` baseline remains the behavioral and visual reference
until every tracked App has been reviewed in every control tab and workspace
page. Startup-only screenshots are insufficient.

Restored in the replacement SDK worktree:

- versioned window titles, project dirty markers, callback busy feedback,
  guarded close behavior, keyboard close, delayed startup progress, and GUI
  test visibility modes;
- fixed control-pane sizing, draggable column and row dividers, scrollable
  control tabs, framework utility menus, and complete-text fitting;
- old panner, range, readonly, adaptive action-grid, file/folder/recursive
  file selection, friendly file labels, multiline control sizing, status,
  log-follow, table, and distinct Usage presentations;
- transparent semantic groups that preserve full native button height, and
  bound range controls whose initial values come from App state rather than
  falling back to their legal limits;
- workspace pages and initial selection, plot view modes, single/pair/stack
  axes layouts, axis titles and labels, unequal axes sizing, per-axis wheel
  zoom, viewport preservation, managed fixed-canvas resize reflow, and plot
  pop-out/export behavior.

Still open before compatibility retirement:

- audit the final public `labkit.app` surface for authoring-level hierarchy:
  keep `Definition` as the single App aggregate root, keep
  `CallbackContext` as an injected runtime port rather than a second
  author-created entrypoint, move compiler/runtime/testing implementation out
  of those facade files, and remove or relocate optional context methods that
  tracked Apps do not justify;
- verify the restored window/startup/close contracts against every App and
  cover startup failure presentation;
- finish the all-App control, menu, button, tab, workspace-page, plot-layout,
  title, and major-state visual audit against the captured `main` baseline;
- remove remaining App-local visual compensations after their stable behavior
  is represented by framework contracts;
- finish diagnostic samples, project/recovery/result/dialog behavior, focused
  App tests, final changed-file gates, documentation, versions, and history.

Current product audit progress:

| App scope | Status | Evidence |
| --- | --- | --- |
| DIC Preprocess | Complete | All three control tabs, workspace, controls, actions, notes, summary, details, log, and focused GUI workflow compared with `main` |
| CIC | Complete | All three control tabs, old panner geometry, files panel, summary rows, batch table, plot stack, menus, title, exports, project save/restore, and focused GUI workflow compared with `main` |
| Chrono Overlay | Complete | Both control tabs, file actions, Usage, panner, plot options, stacked labeled axes, export/restore workflow, and focused GUI tests compared with `main` |
| CSC | Complete | All three control tabs, file/curve/plot controls, readonly comparison summary, all-cycle table, paired exports, stacked axes, project workflow, and focused GUI test compared with `main` |
| EIS | Complete | All three control tabs, file actions, panners, plot choices, Usage, summary, labeled plot, export/restore workflow, and focused GUI test compared with `main` |
| VT Resistance | Complete | All three control tabs, file/export actions, analysis and plot controls, readonly summary, batch table, stacked axes, project workflow, and focused GUI tests compared with `main` |
| Figure Studio | Complete | Figures/Export/Log tabs, FIG source actions, multiline status, quick exports, Canvas and Style panners, linked font/aspect behavior, fixed-canvas preview, axes handoff, package exports/manifests, and focused unit/GUI tests compared with `main` |
| Response Review and Stats | Complete | Setup/Review/Export/Log tabs, numeric metric windows, status and action rows, nonduplicated summary/details, explicit output selection/clear, reset, default output subfolder, manifest name, Stats/Preview workspace, project restore, and focused unit/GUI tests compared with `main` |
| Remaining 13 tracked Apps | Pending | Captured `main` and replacement all-tab baselines exist; each App still requires control/function/state audit and focused validation |

The accepted public structure is capability-partitioned:
`labkit.app.Definition` and `CallbackContext` form the small root; `layout`,
`view`, `event`, `interaction`, `plot`, `project`, `result`, and `dialog` own
optional or specialized concepts. Layout nodes own direct callbacks and
renderers; Apps maintain no
parallel handler, renderer, or capability registries. Native adapters,
layout-node values, stores, queues, and reconciliation remain under
`labkit.app.internal`. There are no aliases from the new SDK back to old
`labkit.ui` symbols.

The replacement may rewrite the current runtime kernel, definition model,
protocol, interaction system, event transport, capability injection, renderer
commit path, and ownership model. Current source is evidence for required
behavior, not a structural template the replacement must preserve.

Version semantics must remain in the existing facade/App version metadata,
dependency requirements, saved-data migration branches, history, and release
records. Packages, folders, files, functions, classes, type tags, protocol
names, tests, and current manuals must use stable semantic names. The migration
must not create a version-named or transitional architecture.

The redesign should keep App-owned scientific state, calculations, thresholds,
units, importers, exporters, plots, and saved project payloads unchanged unless
an App-specific defect requires a separate change. Most App migration should
therefore be concentrated at the framework seams: `definition`, layout,
presentation, callbacks, interactions, and runtime capabilities.

The following are explicitly rejected as end states:

- a second layer that translates old `view`, `event`, `services`, `Project`,
  `Actions`, `Renderers`, or interaction structs at runtime;
- new aliases that silently route old spellings or old interaction `Kind`
  values to new behavior;
- a nominally small function list whose real public contract still lives in
  arbitrary struct fields, string keys, runtime callback-shape probing, or
  private implementation files;
- keeping an unsuitable current boundary only to avoid editing tracked Apps;
- a framework rewrite that also rewrites stable App science without cause;
- two public UI runtimes shipped indefinitely.

### Why the current boundary is migration debt

The current callable surface is smaller than the contract App authors actually
need to know. Important protocols cross the public boundary as data assembled
or interpreted by private implementation. That makes the effective API hard to
discover, document, validate, version, and keep compatible.

| Current design | Observable problem | Replacement requirement |
| --- | --- | --- |
| `runtime.define` accepts several nested scalar structs | App authors must know fields that are not visible in the function signature; spelling mistakes can survive parsing | Every option name and legal value is declared and validated by its owning public constructor or method |
| `Present` returns `view.controls`, `view.previews`, and `view.interactions` with ad hoc nested fields | The presenter contract is defined by commit code rather than one public type; unsupported fields may be ignored | Presentation is an explicit immutable value with a small documented operation set |
| Control presentation uses generic fields such as `Value`, `Items`, `Data`, and `Enabled` | Legal properties depend on the target control, but the dependency is neither typed nor centrally queryable | Target/property compatibility is validated before the first commit and on every update |
| Interactions use `Kind`, `Value`, `Event`, and an open `Options` struct | Legal kinds, value shapes, option fields, and event payloads are distributed across private editors; aliases and ignored options hide mistakes | Each distinct interaction contract has a named constructor with strict parameters and one documented signal payload |
| Actions receive a generic `event` struct and decode `event.meta` through helpers | The action signature is superficially stable while its useful payload remains variant and hidden | Signals have explicit payload contracts; no open metadata bag is required for normal callbacks |
| Actions receive a nested `services` struct | Capabilities and signatures are injected by a private builder; Apps cannot discover them through MATLAB help or introspection | Actions receive one documented runtime context/capability interface with discoverable operations |
| `services.results` builds outputs and manifests from structs whose schema is implemented privately | Result-writing code relies on another shadow protocol | Output and manifest values have public constructors, validation, and help, or leave the UI boundary if ownership is reassigned |
| `runtime.create` returns a concrete UI registry | Internal control ownership and field layout can become accidental public API | Creation returns an opaque application/session handle, or becomes private when no stable public use case exists |
| Generic option parsers copy any valid MATLAB field name | Typos such as an unknown definition, layout, control, utility, or interaction option can be accepted and later ignored | Unknown names fail immediately with a stable programming-error identifier |
| Case-insensitive lookup and undocumented aliases accept near matches | Incorrect source can appear to work while selecting unintended behavior | Public names use one canonical spelling; no fuzzy matching |
| Callback arity is inferred and several shapes are accepted | Function signatures cannot be understood without reading dispatch internals | Each callback role has one signature, with only explicitly documented alternatives where MATLAB requires them |
| Defaults and fallback behavior are intermingled | A safe omitted option and a malformed caller value can take the same path | Defaults apply only when an optional value is absent; invalid supplied values always fail |
| Public documentation mainly catalogs callable `.m` files | Struct fields, callback roles, events, properties, and injected capabilities escape API governance | The contract catalog includes functions, value types, methods, properties, signals, payloads, legal values, defaults, errors, and lifecycle rules |
| Capability additions are often another field in an open struct | The API grows without a visible design decision or compatibility review | New capability must extend an owned interface or introduce a justified stable concept through the same review gate |
| Resource and UI ownership is implicit in registries and cleanup callbacks | App code can depend on concrete handles or miss a disposal path | Runtime ownership and disposal form an explicit tree with deterministic cleanup |

These are boundary problems, not merely documentation omissions. Documenting
the current hidden schemas would make them visible but would also freeze
several weak contracts. The redesign must first choose better contracts and then
document all of them.

### External design references

The redesign should adapt mature principles, not reproduce another toolkit's language
or object hierarchy:

- Qt's [Object Model](https://doc.qt.io/qt-6/object.html) and
  [Property System](https://doc.qt.io/qt-6.11/properties.html) make properties,
  signals, and callable behavior part of a queryable type contract. The framework
  should make presentation properties and signal payloads equally explicit.
- Qt's [Object Trees and Ownership](https://doc.qt.io/qt-6/objecttrees.html)
  give parent-owned objects deterministic lifetime. The framework should give the
  runtime ownership of figures, controls, interactions, timers, listeners, and
  disposable resources instead of exposing the ownership registry to Apps.
- Qt's [Model/View Programming](https://doc.qt.io/qt-6/model-view-programming.html)
  separates data from representation through small standard interfaces. The framework
  should preserve App state as the model, keep layout/presentation
  declarative, and define small table/list/plot presentation contracts.
- Qt's [release compatibility policy](https://doc.qt.io/qt-6/qt-releases.html)
  reserves breaking source changes for a major version, while its
  [platform abstraction](https://doc.qt.io/qt-6/qpa.html) is explicitly
  private. The framework should promise source compatibility inside its
  declared compatible range and make internal MATLAB UI adapters unambiguously
  private.
- Flutter's
  [declarative UI model](https://docs.flutter.dev/data-and-backend/state-mgmt/declarative)
  and [architecture](https://docs.flutter.dev/resources/architectural-overview)
  derive immutable UI descriptions from state. The framework should retain a
  one-directional `state -> presentation` path without returning concrete UI
  handles to App presenters.
- GObject's [type system](https://docs.gtk.org/gobject/concepts.html) and
  [signals](https://docs.gtk.org/gobject/signals.html) register names,
  parameter types, and signal signatures centrally. The framework should have one
  contract registry from which validation, help, and documentation tests can
  be generated or checked.
- GTK's [list model design](https://docs.gtk.org/gtk4/section-list-widget.html)
  deliberately uses a small reusable data interface across multiple views.
  The framework should avoid control-specific table/list data bags when a stable small
  model interface is sufficient.

### Frozen design principles

The following decisions apply before exact MATLAB symbol names are frozen:

1. **One public contract, not a public layer plus a shadow schema.** Public API
   includes functions, constructors, public value types, methods, properties,
   callback signatures, signal payloads, legal named values, defaults, error
   identifiers, ownership, and lifecycle.
2. **Strict construction.** Validate as much as possible when an App
   definition, layout node, presentation operation, interaction, or result
   value is constructed. Validate cross-references in a compile step before a
   figure is created.
3. **Explicit behavior.** A supplied unsupported name, type, shape, identifier,
   combination, or callback signature is a programming error. It is never
   ignored or reinterpreted.
4. **Defaults are not recovery.** A documented default is used only when an
   optional argument is omitted. It never replaces an invalid supplied value.
5. **Small concepts, complete contracts.** Minimize the number of concepts an
   App author learns, not merely the number of public function files. A
   distinct value or signal contract deserves a visible name; cosmetic
   variants do not.
6. **Composition over special cases.** Workspace pages, control groups, plot
   areas, and interactions compose from the same small layout and presentation
   vocabulary. App-specific workflow meaning stays in the App.
7. **Declarative state flow.** Actions produce validated App state;
   presentation derives a complete immutable view description from that state;
   the runtime reconciles it transactionally.
8. **No registry escape.** App code does not receive the concrete control
   registry, lifecycle queues, timers, listeners, editor instances, or
   framework layout handles.
9. **Runtime-owned lifetime.** The runtime owns UI and managed resource
   lifetimes and disposes children with their owning interaction, preview,
   session, or application scope.
10. **Stable inside one declared compatibility range.** Once the replacement
    is released, compatible additions may add
    optional operations or new standalone concepts, but must not change
    existing meaning, defaults, payloads, callback signatures, or errors.
11. **Private means private.** Platform adapters and concrete MATLAB component
    mappings carry no compatibility promise and are not referenced by Apps,
    examples, or public docs.
12. **Capability growth does not require framework internals.** An App author
    should learn a new optional constructor or method when using a genuinely
    new concept, not a new registry shape, dispatch convention, or hidden
    service protocol.
13. **The paved road minimizes App wiring.** Layout owns strict field
    bindings, Application collects signal Commands, runtime combines defaults
    and bindings with App-provided dynamic presentation, and ordinary Apps do
    not repeat capability metadata. Internal SDK complexity is acceptable when
    it removes repeated App callbacks, presenters, lifecycle code, or
    synchronized registries.
14. **Injected types are visible at the function boundary.** Apps do not pass
    SDK objects through untyped app-local parameters merely to assemble a
    definition. Runtime callback `arguments` blocks declare
    `CallbackContext` and the exact event payload type before the body uses
    their methods or properties.

### Target architecture

The target data flow is:

```text
App definition
  |-- durable App project/session state
  |-- immutable semantic layout
  |-- explicit commands and signals
  |-- pure presentation(state)
  |-- plot renderers
  `-- declared project/result behavior
             |
             v
Contract compiler
  |-- validates names, types, IDs, links, callbacks, and capabilities
  `-- produces a private compiled application plan
             |
             v
Runtime kernel
  |-- transactional state/action queue
  |-- typed runtime context
  |-- presentation reconciliation
  |-- ownership/resource tree
  |-- project/recovery/result coordination
  `-- private MATLAB UI platform adapter
```

The App-facing layers should be limited to the following stable concepts.
Exact symbol spelling is accepted only after the contract prototypes described
below.

#### App definition

- Keep one obvious definition entry and one launch entry.
- Required product metadata remains explicit in the definition signature.
- Replace open `Project`, `Actions`, `Renderers`, and `Utilities` structs with
  validated public values or owned builder methods.
- A layout control binds one concrete callback with one documented signature.
  Plot areas bind their concrete renderer. Callback roles, target IDs, and
  plot targets are checked before UI creation.
- Static Apps do not need empty placeholder registries or presenter functions.

#### Layout and the right-side workspace

- Layout values are immutable semantic descriptions. App code never sets
  concrete `uigridlayout`, pixel, component, or registry fields.
- Every layout constructor declares its complete name-value set and rejects
  unknown names.
- `labkit.app.layout.workspace` remains the single public entry for organizing
  the right-side workspace. A single-page App supplies one content layout.
  A multi-page App adds named pages through the returned workspace value or
  another operation owned by `workspace`; the replacement must not expose a parallel
  `workspaceTab` constructor or require a new top-level API for each workspace
  capability.
- Page ID, title, content, initial selection, and optional availability are
  explicit parameters. Page switching is framework behavior; workflow meaning
  stays in the App.
- The compile step rejects duplicate page IDs, an unknown selected page,
  invalid nesting, and content owned by more than one parent.
- Existing single-workspace Apps should require no conceptual change and,
  after any one-time syntax migration, no page-specific code.

A provisional shape, used only to test the concept count, is:

```matlab
workspace = labkit.app.layout.workspace(singleContent);

workspace = labkit.app.layout.workspace();
workspace = workspace.page("data", "Data", dataContent);
workspace = workspace.page("plot", "Plot", plotContent);
workspace = workspace.initialPage("data");
```

This sketch recommends an owned `page` operation rather than another global
constructor. It does not approve MATLAB classes by itself.

#### View snapshot

- Replace arbitrary nested presenter structs with one immutable view snapshot
  value.
- Its public operations should cover stable semantic changes such as control
  value, enabled/visible state, choices, table model, text, plot model,
  workspace page state, focus, and managed interaction.
- Each operation identifies a declared target and accepts only properties
  legal for that target type. The compiler can precompute target capability,
  while commit-time validation protects dynamic values.
- A presenter cannot create controls, acquire axes, reach component handles,
  or set arbitrary MATLAB properties.
- Plot presentation identifies a declared renderer and passes only its
  documented App model. The platform-owned axes are supplied to the renderer,
  not stored in App state.
- A stale plot is App state rendered through an explicit plot status or
  placeholder contract, not an implicit comparison of UI handles.

A provisional discoverable value-style API is:

```matlab
function view = present(state)
    view = labkit.app.view.Snapshot();
    view = view.value("worksheet", state.session.sheet);
    view = view.choices("group", state.session.groupNames);
    view = view.tableData("dataTable", state.session.tableModel);
    view = view.enabled("runTest", state.session.canRun);
    view = view.renderPlot("resultPlot", "groupComparison", state.session.plotModel);
    view = view.workspacePage("plot", Enabled=state.session.hasResult, ...
        Status=state.session.plotStatus);
end
```

The final method set must be derived from audited App needs. It must not become
a generic `set(target, property, value)` escape hatch.

#### Controls, tables, lists, and models

- A control constructor owns its value type, editable state, legal events,
  legal presentation operations, defaults, and validation.
- Table/list data use the smallest reusable model contract that covers
  selection, editing, choices, row identity, and displayed values. App-owned
  tables remain ordinary MATLAB data where possible.
- Editable-table events carry explicit row/column identity and the new value;
  Apps do not decode `event.meta`.
- Per-cell categorical choices are a declared table capability with validated
  choices, not an undocumented field added to a control model.
- Model changes that invalidate a rendered result are represented in App state
  and can be presented consistently on any workspace page.

#### Interactions

- Remove the public `Kind` string switch and open `Options` bag.
- Provide one named constructor per genuinely different value and signal
  contract. The initial audit must cover at least point paths, paired points,
  fixed point slots, rectangles, region selections, intervals, and scale
  references.
- ROI and scale tools are framework interactions, not fragments of a generic
  struct maintained independently by each App.
- Each constructor documents target preview/axis, initial value, constraints,
  visual defaults, callback payload, edit policy, cancellation, and cleanup.
- Visual styling options are strictly named and validated; unknown styling
  options fail.
- Display-only graphics remain renderer output with hit testing disabled.
  Editable overlays remain runtime-owned interactions and preserve the
  viewport through a documented policy.

The intended usage is conceptually:

```matlab
scale = labkit.ui.interaction.scaleReference( ...
    Target="image.main", Points=state.session.scalePoints, ...
    Changed=@scaleChanged, Color=[1 1 1]);

roi = labkit.ui.interaction.rectangle( ...
    Target="image.main", Bounds=state.session.roi, ...
    Changed=@roiChanged, Limit=state.session.imageBounds);
```

There is no `"Kind", "rectangle"` or arbitrary `"Options", struct(...)`
equivalent in the replacement contract.

#### Signals, commands, and action callbacks

- Prefer direct, role-specific callbacks or explicit command values over
  unrelated string IDs joined through registries.
- Each signal declares its callback signature and payload. Simple controls may
  pass a primitive value; selections and interactions use small public payload
  values when multiple named fields are necessary.
- Remove generic `event.meta` and event-decoding helpers from normal App code.
- Programmatic dispatch, startup work, and queued follow-up commands remain
  possible through explicit command references.
- The runtime preserves FIFO processing, whole-state validation,
  transactional presentation, and rollback on failed actions.
- Callback arity is not guessed by catching invocation errors. Any supported
  role variation is declared at construction and validated before launch.
  A command may query the fixed function definition with `nargin(handle)` and
  `nargout(handle)` exactly once during strict construction; negative
  variable-arity results are rejected. Runtime dispatch never probes or
  retries a callback with another shape.

The contract prototype must choose one of these two explicit models:

1. role-specific callbacks such as `(state, value, context)` and
   `(state, context)`; or
2. one `(state, payload, context)` signature where `payload` is a documented
   public value type for the originating signal.

It must not choose a generic open event struct.

#### Runtime context and capabilities

- Replace the nested `services` struct with one documented runtime context
  interface. MATLAB help and introspection must reveal every operation and its
  signature.
- Common operations should be direct and plainly named: dispatch a command,
  append workflow status, report a caught domain error, show an App-parented
  dialog, choose input/output paths, save a named project or recovery copy,
  create/reconcile source records, acquire a declared preview target, manage a
  scoped resource, and write validated result metadata.
- Do not expose `figure`, debug internals, launch request internals, registry
  maps, or platform controls merely because they are convenient to the
  implementation. A genuinely necessary advanced capability must have a
  narrow interface and an ownership rule.
- Dialog cancellation is an expected result with an explicit return value.
  Invalid arguments to a dialog method are programming errors.
- Managed resources declare scope and cleanup once. Replacing or ending the
  owning scope disposes the prior resource deterministically.
- Test doubles implement the same context contract. Production code does not
  branch on a test-only field in an open struct.

#### Project and result contracts

- Saved App payload versions are independent from facade compatibility. The runtime must
  not rewrite a valid saved payload simply because the presentation boundary
  changed.
- Project creation, validation, migration, resume, relink, and legacy import
  callbacks are represented by an explicit project specification value.
- Result output and manifest schemas are explicit public values if they remain
  framework capabilities. Required/optional fields, media type, status,
  warnings, extensions, path rules, and error behavior are documented beside
  their constructors.
- If the architecture review concludes that a project or result operation is
  not owned by the UI/application runtime, reassign it to an already permitted
  stable LabKit facade rather than creating public `data`, `io`, `util`, or
  App-specific framework packages.
- No callback or writer accepts an arbitrary schema extension unless the
  extension point is named, versioned, namespaced, and round-trip tested.

#### Public representation

Arbitrary App-authored structs are forbidden for replacement contracts. Private
implementation may use structs after validated construction because internal
representation is not the API.

The contract prototype must compare:

- a small set of sealed immutable value classes with documented constructors
  and methods; and
- opaque values created only by strict public constructor/accessor functions.

The accepted direction is a small set of sealed immutable value objects
because MATLAB exposes their methods and properties through help and
introspection, and each object rejects invalid state at construction. The
repository owner delegated the architecture decision after reviewing the
disposable value-class and opaque-function evidence on 2026-07-19. This
authorizes production `classdef` contract values for this migration, but not a
public inheritance hierarchy or mutable handle-state model. The function-only
alternative remains rejected because Apps could inspect closure backing state
through `functions`.

### Error, default, and recovery policy

The runtime must classify failures instead of routing all of them through fallback
behavior.

| Condition | Required behavior |
| --- | --- |
| Optional parameter omitted | Use the documented default |
| Unknown name-value argument or presentation operation | Throw immediately |
| Duplicate or unknown ID/reference | Reject during contract compilation |
| Wrong type, size, shape, range, or callback role | Reject at construction or compilation |
| Unsupported option combination | Throw with the conflicting parameter names |
| Unknown interaction type or alias | No dispatch exists; constructor name must be valid |
| Presenter targets a property unsupported by the layout node | Throw before committing a partial view |
| Renderer or command reference is missing | Reject before figure creation |
| User cancels a native dialog | Return an explicit cancellation result without an error |
| External file is unavailable or invalid | Return/throw the documented operational outcome; the App decides user-facing remediation |
| App action throws | Roll back state/view, preserve diagnostics, and surface the failure |
| Internal invariant fails | Throw a distinct framework error; never continue with guessed state |

Additional rules:

- no case-insensitive public-name matching;
- no undocumented alias table;
- no catch-all that retries with a different signature or shape;
- no ignoring unknown struct fields;
- no silent scalarization, truncation, reshaping, or replacement of a supplied
  invalid value;
- only documented, lossless text/container normalization may occur;
- error identifiers for public validation groups are stable inside the
  declared compatible range and
  include the invalid symbol or parameter in the message;
- native MATLAB exceptions may be wrapped only when the wrapper adds the
  failed public operation and preserves the original cause.

An offline migration analyzer may recognize old spellings to explain how to
edit source. The production runtime must not recognize them.

### API stability and governance

The replacement is not considered stable until it has a machine-checked contract
inventory. That inventory must cover:

- public functions and constructors;
- public types, methods, readable properties, and allowed construction paths;
- layout nodes and their legal children/options;
- presentation operations and compatible target kinds;
- signals, callback signatures, and payload fields/types;
- interaction constructors, values, constraints, and signals;
- runtime-context methods and lifecycle effects;
- project/result schemas and version behavior;
- legal string/enumerated values and canonical spelling;
- defaults, errors, cancellation, and ownership;
- minimum MATLAB release and declared MathWorks products.

The inventory is a governance source, not another hand-authored runtime
configuration bag. Public help and documentation consistency tests must prove
that every inventory entry has syntax, inputs, outputs, defaults, legal values,
errors, and related APIs. Reflection or tests should detect public symbols that
are absent from the inventory.

Inside one declared compatible facade range:

- existing valid source retains meaning;
- additions are optional and backward compatible;
- changing a default, callback signature, event payload, ownership rule, or
  error category is breaking;
- removal requires the next major version;
- experimental implementation is private until its contract is accepted;
- no public `experimental`, `legacy`, `compat`, `v7`, or `next` namespace is
  shipped as a way to bypass review.

Public API review evaluates concept count and App call sites, not just function
count. One constructor per stable concept is preferable to one generic
constructor with a hidden string switch. Conversely, a new public function for
every visual preference is rejected; those are strict parameters on the owning
concept.

### Migration strategy

Development may be staged on a dedicated branch, but the released source
boundary changes atomically. The current runtime remains the working baseline
until the replacement and all tracked Apps pass their gates. A temporary
implementation must remain private and unreleased; it must not establish a
second public or version-named namespace.

Before a migration branch is ready for PR review, keep it stable through small
logical commits and focused tests for the current step; do not repeatedly run
broad repository gates. User documentation, facade/App versions, and structured
history describe the single net transition from the mainline merge base to the
final squash result, never the intermediate commit sequence. Phase 8 owns the
broad validation and final version/history reconciliation.

#### Phase 0 - freeze and evidence baseline

Deliverables:

1. Freeze new current-runtime public symbols and new hidden struct fields except for
   release-blocking fixes already in flight.
2. Record the exact current public callable surface and every shadow contract:
   definition/project fields, layout fields, control presentation fields,
   preview/renderer models, interaction kinds/options/values, event metadata,
   service operations, resource scopes, result schemas, and registry fields.
3. Inventory every version-named package, folder, file, function, class, type,
   protocol, test, and current-manual section. Classify dedicated version,
   dependency, saved-data migration, history, and release metadata as the only
   allowed version-bearing locations.
4. Scan all 21 cataloged Apps and build a capability matrix of actual use,
   including callback shapes and private-API reach-through.
5. Capture representative UI behavior, saved-project fixtures, result
   manifests, focused test results, startup time, first-presentation time, and
   repeated-presentation time.
6. Separate required behavior from accidental current-runtime behavior. Every retained
   behavior gets an owner and test; accidental behavior is explicitly rejected.

Gate:

- no replacement API design begins from memory or from a single App;
- every current App call pattern is classified as retain, replace, move to App,
  or remove;
- baseline evidence includes the current late-failure cases: incompatible
  control values accepted until MATLAB handle creation, tests coupled to
  concrete layout containers, and empty or malformed App state reaching an
  action before normalization.

#### Phase 1 - contract RFC and executable prototypes

Phase 1A selects the public representation. Phase 1B proves the complete
contract through an end-to-end prototype and runtime/performance evidence.
Representation acceptance alone does not open the Phase 2 production gate.

Create a reviewed replacement-contract RFC with:

- the complete proposed public vocabulary;
- callback and signal signatures;
- ownership/lifecycle diagrams;
- error and cancellation taxonomy;
- target syntax for a static App, a table/editing App, a multi-page plotting
  App, an image/ROI App, and a resource-owning video App;
- a source-compatibility promise and versioning rules;
- the value-class versus strict function-value decision;
- the final location/ownership of project and result capabilities.

Build disposable, non-release prototypes against three contrasting Apps:

- T-Test Wizard: editable tables, categorical group selection, workspace
  pages, plots, and stale-result presentation;
- Curvature Measurement: point editing, scale reference, overlays, plot
  renderers, and viewport preservation;
- Video Marker: long-lived resources, repeated interactions, recovery,
  project compatibility, and lifecycle cleanup.

Prototype acceptance:

- each example can be understood from public help without reading framework
  private code;
- an unknown argument, target, signal, or interaction option fails at the
  nearest boundary;
- no App-authored raw UI transport struct remains;
- no App code reads a UI registry or concrete component;
- the replacement form has fewer independent concepts and no more
  framework-seam code than the current form, unless an added line makes a formerly hidden
  contract explicit;
- presentation remains deterministic and testable without a visible GUI;
- performance thresholds are set from Phase 0 evidence before implementation.
- value and alternative representations compile identical target graphs;
- public programming errors use stable `labkit:ui:contract:*` identifiers;
- presentation is a complete snapshot reconciled by the runtime, never an
  App-authored patch protocol;
- Apps declare required runtime-context capabilities and cannot retain an
  acquired render surface.

The prototypes are evidence, not compatibility shims. Reject and redesign the
contract if they require per-App exceptions.

Phase 1 acceptance evidence is
`.agents/migration/ui-explicit-contract/phase-1-prototype-evidence.*` and
`phase-1-end-to-end-evidence.*`. The end-to-end experiment establishes the
implementation route: compile the static Application graph once, validate
complete presentation snapshots against that graph, and keep diff/reconcile
private to the runtime.

#### Phase 2 - strict contract kernel

Implement the accepted public values and compiler independently of concrete
MATLAB controls:

1. strict constructors and canonical value validation;
2. global ID/reference checking and layout ownership validation;
3. callback-role validation without exception-based arity probing;
4. presentation target/capability checking;
5. signal/payload declarations;
6. deterministic diagnostic rendering for contract errors;
7. the public contract inventory and help checks.

Use synthetic definitions to test the kernel. Do not connect an open current-runtime
struct parser to the new compiler.

Gate:

- a malformed application cannot produce a partially compiled plan;
- negative tests exist for every rejected fallback and ambiguity listed above.

#### Phase 3 - runtime and platform rewrite

Implement a new runtime kernel around the compiled plan:

1. a transactional command queue and validated state boundary;
2. immutable presentation reconciliation;
3. runtime context/capability implementation and test double;
4. parent-owned UI, interaction, listener, timer, and resource lifetimes;
5. private MATLAB component/layout adapters;
6. renderer invocation and viewport policy;
7. dialogs, project/recovery operations, and result writing through their
   accepted contracts;
8. diagnostics that preserve programming failures instead of continuing.

The platform adapter may reuse proven leaf algorithms from the current runtime,
but only behind replacement interfaces. Copying the current registry or commit schema wholesale
does not satisfy this phase.

Gate:

- the runtime can run the RFC examples without current dispatch, presentation,
  service, interaction, or compatibility code.

#### Phase 4 - interaction and model completion

Implement and validate the complete capability set from the App matrix:

- basic controls and signals;
- editable/categorical tables and selection models;
- lists and file/source presentation;
- plots and multi-axis previews;
- workspace single-page and multi-page behavior;
- point, paired-point, point-slot, rectangle, region, interval, and
  scale-reference interactions;
- managed resources and cleanup;
- project/recovery and results contracts;
- framework tools that remain justified.

Each capability receives:

- public help and a minimal clean-session example;
- constructor, compile, runtime, and negative validation tests;
- lifecycle/cleanup tests when it owns resources;
- one real migrated App call site before the contract is frozen.

Gate:

- no capability is considered complete if its legal parameters or signal
  payload must be learned from private code.

#### Phase 5 - App migration tooling

Create repository-owned, offline migration support:

- a read-only analyzer that reports current definitions, raw presenter paths,
  interaction kinds/options, generic event decoding, service calls, registry
  access, callback roles, and undocumented aliases by source location;
- a migration worksheet mapping each current pattern to one replacement operation;
- narrowly scoped mechanical rewrites where the transformation is unambiguous;
- a post-migration guard that fails on remaining retired boundary patterns;
- examples showing before/after definition, presentation, interaction, and
  callback code.

Generated edits must be normal reviewed source. The analyzer/codemod does not
ship in the App runtime and does not guarantee semantic correctness.

Gate:

- a representative App can be migrated without learning runtime internals and
  without a runtime adapter.

#### Phase 6 - migrate tracked Apps in capability waves

Use the catalog and Phase 0 matrix as the authoritative list. The current
21-App order is:

1. **Plot-centric baseline:** Chrono Overlay, CIC, CSC, EIS, VT Resistance, and
   ECG Print.
2. **Data/transformation workflows:** DIC Postprocess, Focus Stack, Image
   Enhance, Image Match, Figure Studio, and T-Test Wizard.
3. **Managed-interaction workflows:** DIC Preprocess, Batch Image Crop,
   Curvature Measurement, FLIR Thermal, and Video Marker.
4. **High-state workflows:** Gait Analysis, Nerve Response Analysis, Response
   Review and Stats, and RHS Preview.

The order may change when the capability matrix shows a better dependency
order, but no App is omitted. For each App:

1. run its current focused tests and capture the behavioral baseline;
2. migrate only framework seams first;
3. remove App-local UI transport helpers made obsolete by explicit contracts;
4. preserve project payload version and scientific outputs unless separately
   justified;
5. run focused core and GUI tests;
6. inspect raw presenter/service/interaction patterns with the migration guard;
7. perform the documented manual workflow, including native dialogs and
   pointer interactions where applicable;
8. record any missing general capability as a framework design issue, not an
   App-specific escape field.

No App is allowed to maintain a local retired-contract compatibility layer. A private App
uses the same analyzer and worksheet and must migrate before it can declare
compatibility with the replacement.

#### Phase 7 - delete the retired boundary and adapters

After all tracked Apps run directly on the replacement:

- remove retired definition parsing, presenter commit, generic event metadata,
  service-bag construction, interaction `Kind` dispatch, aliases, registry
  return values, and compatibility-only tests;
- remove temporary prototypes, bridge code, and dual-path flags;
- rename or remove version-bearing architecture files, symbols, tests, and
  current documentation; keep numeric versions only in their dedicated
  metadata, persistence/migration, history, and release owners;
- prove by search and contract tests that Apps cannot call a retired pattern;
- retain the retired contract only in Git history and the last compatible
  release/tag, not in
  the production tree.

Gate:

- deleting retired code changes no replacement App behavior or test result.

#### Phase 8 - documentation, version, and release

Before merge or direct-main push:

1. have the version owner assign the next incompatible facade version and
   update every App requirement to its accepted compatible range;
2. update each affected App source version and owning manual where its source
   contract changed;
3. add one structured cross-component history record listing the UI facade and
   all migrated Apps, with compatibility, user/data impact, validation, and
   evidence;
4. replace current framework and App-development manuals with the accepted
   replacement contract and migration examples;
5. update public help and path-owned navigation, then regenerate the site;
6. run documentation consistency, contract, focused GUI/core, `changedFast`,
   and one stable `buildtool changed` gate;
7. complete developer-led interactive validation of every affected workflow
   class before a release;
8. follow the normal release process only for the exact validated commit.

The upgrade note must state plainly that the replacement is source-breaking for App
definitions and presenters, while saved project compatibility remains governed
by each App payload version.

### App-impact containment

Minimizing App migration cost is a design constraint, but not a reason to keep
the old boundary.

Expected to remain unchanged:

- App entrypoint behavior and launcher command;
- durable project field meaning and payload version;
- transient App state meaning where it is not UI-registry state;
- scientific computation, selection rules, units, thresholds, and validation;
- file parsers, domain transforms, exports, and plot calculations;
- renderer bodies that already accept axes plus an App model and do not reach
  into framework registries;
- visible workflow order and reader-facing language unless the App has a
  separate usability change.

Expected to change mechanically:

- open structs in `definition` become strict definition/project/command/
  renderer values;
- presenter field assignment becomes explicit presentation operations;
- interaction structs become named constructors;
- `services.*` calls become runtime-context operations;
- generic event/meta decoding becomes the signal's direct value or public
  payload;
- raw axes/registry access becomes declared renderer or narrow context
  capability;
- workspace page configuration moves under the single workspace contract.

Potentially non-mechanical changes requiring review:

- callbacks whose current behavior depends on ignored fields, fuzzy names,
  inferred arity, concrete handles, or undocumented event metadata;
- Apps that keep UI handles, timers, or listeners in session state;
- App-specific interaction editors that duplicate framework ownership;
- project/result code that depends on a private struct field;
- code that catches a programming error and continues with a guessed value.

### Risks and controls

| Risk | Consequence | Control |
| --- | --- | --- |
| Rewriting too broadly | Scientific behavior changes with the framework | Freeze domain outputs and saved fixtures; migrate framework seams separately |
| Designing from one App | New special cases appear late | Capability audit of all 21 Apps plus three contrasting prototypes |
| Recreating hidden structs behind new names | Same debt returns | Contract inventory includes fields, payloads, methods, errors, and lifecycle; Apps cannot author raw transport structs |
| Public class hierarchy becomes complex | MATLAB learning cost and inheritance debt | Prefer few sealed value types and composition; prototype against a strict function-only alternative before approval |
| Function-only API becomes symbol sprawl | Discoverability degrades | One constructor per stable concept, owned methods/options for capabilities, and an explicit concept budget |
| Generic setter returns | Invalid target/property combinations survive | Only named semantic presentation operations with capability checks |
| Runtime adapters become permanent | The framework retains two semantics | No adapters in a released runtime; offline migration only; Phase 7 deletion gate |
| Strict validation exposes many latent App defects | Migration appears larger than expected | Analyzer, source-location diagnostics, capability waves, and focused baseline tests |
| Callback/event redesign loses behavior | Actions respond to the wrong selection or source | Signal-by-signal payload inventory and negative tests before migration |
| Ownership rewrite leaks or disposes resources early | Video/image interactions fail over time | Parent-scope lifecycle tests and manual long-running workflows |
| Project UI rewrite changes saved data | Users cannot reopen work | Keep payload versions independent; fixture round trips and legacy-import tests |
| Renderer isolation reduces advanced plots | Apps reach around the framework again | Audit renderer needs; add narrow declared axes/model capabilities, never registry access |
| New validation hurts startup or presentation speed | Apps feel slower | Phase 0 baselines, prototype thresholds, and measured profiling before freeze |
| MATLAB release/component differences leak into API | The runtime behaves differently by installation | Private platform adapter, declared product requirements, and supported-release tests |
| Private Apps are stranded | Local workflows remain on the retired contract | Publish analyzer/worksheet before replacement release; no false compatibility declaration |
| Documentation drifts from implementation | Hidden API returns | Contract catalog and public-help consistency checks in required validation |
| Long branch diverges from ongoing App work | Merge risk grows | Rebase coherent checkpoints, keep App science changes separate, and migrate in reviewed waves |

### Completion and removal conditions

This debt entry is complete only when all of the following are true:

- the replacement contract is the only production UI runtime in the
  repository;
- all 21 cataloged Apps call it directly and declare the accepted facade
  requirement;
- no App authors or reads a raw UI definition, presentation, interaction,
  event-meta, service, result, or registry transport struct;
- no public parser accepts unknown names, aliases, fields, or invalid supplied
  values;
- no production runtime adapter translates retired source contracts;
- every public function/type/method/property/signal/payload/default/error and
  ownership rule is represented in the contract inventory and documented;
- no package, folder, file, function, class, type, protocol, test, or current
  architecture/manual name carries version semantics;
- strict negative tests cover the rejected fallback classes;
- incompatible control values fail during definition compilation, workspace
  behavior is testable without concrete MATLAB container properties, and App
  state is normalized or rejected at the action boundary;
- saved project fixtures and scientific App outputs retain their declared
  compatibility;
- focused, contract, documentation, lifecycle, GUI, performance, and required
  repository validation pass;
- developer-led manual validation covers native dialogs, editable tables,
  workspace pages, plot invalidation, ROI/scale tools, pointer interaction,
  resource cleanup, project recovery, and representative exports;
- the cross-component history record contains the exact validation evidence;
- retired code, migration-only bridge code, and debt-only guardrails are deleted.

At that point, move durable replacement design and compatibility promises into
`docs/framework/`, `docs/development/build-apps/app-development.md`, public
MATLAB help,
the API catalog, and component history. Then delete this entire active debt
entry in the same change. Do not preserve the completed roadmap here.

## Intentional compatibility

Read-only saved-data compatibility is not automatically migration debt. Retain
it when current user files need it and the current writer always emits the
current format:

- Video Marker imports its declared legacy project variable and writes the
  current `labkitProject` envelope.
- Current App project specs migrate supported older payload versions through
  one version-aware `Migrate` entry.
- `labkit.dta` retains documented legacy field aliases beside canonical,
  unit-explicit fields until a future major-version decision.

Do not use a saved-data promise to justify old source layouts, launch factories,
migration callback collections, or undocumented UI nodes.

## Maintaining the ledger

Open an entry only for a concrete current problem with an owner, observable
effect, focused test, completion criteria, and removal condition. Do not treat
file length, helper count, or a possible future abstraction as migration debt.

Temporary MathWorks Toolbox use must record the exact source symbol, product,
owner, repository fallback, fallback test, idempotency evidence, numeric parity
outputs and tolerance, and the condition for deleting the Toolbox branch. Its
machine-readable declaration lives in
`tests/runner/labkitToolboxDebt.m`.

When an entry is resolved, delete it and any debt-only guardrail in the same
change. Preserve durable decisions and evidence in the owning manual and
component history when project policy requires them.
