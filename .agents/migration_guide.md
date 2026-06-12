# Agent Migration Ledger

This is the agent-facing migration ledger for LabKit. It is not an
architecture manual, validation matrix, historical changelog, or standalone
roadmap.

Human-facing architecture and app behavior live in `docs/`. Exact validation
commands live in `docs/testing.md` and are routed through
`labkit-test-planner`. This ledger owns only active migration debt facts,
retirement rules, and the minimum standard for handling future migration debt.

## Lifecycle

Update this ledger when migration debt is added, reduced, retired, or
reprioritized. Keep it aligned with:

- `ProjectDebtGuardrailTest.expectedOversizedRunnerDebtFiles`
- `ProjectDebtGuardrailTest.expectedAppPrivateDebtFiles`
- `ProjectDocumentationGuardrailTest.expectedPrivateContractDebtFiles`
- `ProjectStructureGuardrailTest` package and startup path checks
- `docs/architecture.md` for human-facing boundary facts

When debt is retired, remove stale expected-debt entries and shrink this file in
the same change. A completed migration should not remain as active roadmap text.

## Current Debt Snapshot

Current active migration debt:

```text
ui-2-declarative-spec
```

Current facts:

- Oversized app entry points: none.
- Oversized app `+ui/runApp.m` runners over 500 lines: none.
- App `private/` debt: none.
- `+labkit` private helper contract debt: none.
- String-dispatch workflow adapters and app `+core/dispatch.m` routers: none.
- UI app-facing style debt is active: ordinary app UI still exposes
  `createShell`, `tab`, `section`, `form`, `panel`, `draw`, `update`, `place`,
  explicit grid sizes, row heights, right-grid sizing, and direct
  `Layout.Row`/`Layout.Column` mechanics.
- The UI 2.0 foundation slice has landed: public spec constructors,
  `labkit.ui.app.create`, named view helpers, GUI-free validation,
  public-surface guardrails, and reusable UI structural tests exist.
- The first migrated app slice is complete: `labkit_ImageMatch_app`,
  `labkit_ImageEnhance_app`, and `labkit_FocusStack_app` now launch through
  `labkit.ui.app.create` and no longer carry ordinary old-UI layout code.
- Current image-app evidence still supports a narrow public surface. The
  migrated apps needed `pathPanel.selectionMode`,
  `pathPanel.onSelectionChange`, and `previewArea.onModeChange`, but they did
  not justify public primitive constructors or a larger file-panel API.
- Human docs, scoped `AGENTS.md`, repo skills, public-surface guardrails, and
  GUI structural tests should describe the implemented foundation as current
  behavior while keeping app migration order in this ledger.

Completed migration baseline: ECG Print, DIC Preprocess, DIC Postprocess, CIC
runner normalization, and CSC runner normalization are complete. Treat them as
guarded baselines, not active phases.

No active runner maps exist. If a future guardrail records new runner debt, add
only a narrow map for the specific file and delete it when the debt is retired.

## Active Migration: UI 2.0 Declarative Spec

### Goal

Replace the pre-2.0 app-facing UI construction style with a declarative,
semantic UI contract:

```text
apps describe controls, sections, previews, logs, and callbacks
+labkit.ui owns layout mechanics, registries, resize behavior, and app-neutral
updates
apps keep workflow semantics, calculations, plotting annotations, exports, and
log wording
```

The migration is worthwhile only if it removes real app-author burden and
prevents the same style drift from returning. It must not be a cosmetic move
from large app files into large framework helpers.

### Problems To Eliminate

The current UI facade fixed the old flat `labkit.ui.*` sprawl, but app code
still leaks low-level layout and action mechanics:

- app specs pass `gridSize`, `rowHeight`, `resizeRows`, `rightGridSize`, and
  `rightRowHeight`
- apps manually set `Layout.Row` and `Layout.Column`
- apps and tests depend on row placement rather than semantic control identity
- app-local `place(...)` helpers hide but do not remove physical layout coupling
- `labkit.ui.view.draw` and `labkit.ui.view.update` use string actions and
  varargs instead of named operations
- file/log/table/text panels encode special cases under one action-style
  `panel` surface
- docs and scoped agent rules still point new app authors at the pre-2.0 style
- GUI structural tests over-assert row/column details for reusable UI helpers

### Stable Minimal UI 2.0 Surface

UI 2.0 is a narrow framework for LabKit workbench apps, not a general MATLAB GUI
DSL. Public spec APIs express stable LabKit app shapes. MATLAB primitive controls
are implementation details unless repeated real app use proves that a primitive
has become a stable LabKit app shape.

The stable app-facing surface is:

```text
labkit.ui.app.create
labkit.ui.app.dispatchRequest
labkit.ui.app.runBusy

labkit.ui.spec.app
labkit.ui.spec.workspace
labkit.ui.spec.tab
labkit.ui.spec.section
labkit.ui.spec.field
labkit.ui.spec.rangeField
labkit.ui.spec.action
labkit.ui.spec.actionGroup
labkit.ui.spec.pathPanel
labkit.ui.spec.previewArea
labkit.ui.spec.resultTable
labkit.ui.spec.logPanel
labkit.ui.spec.statusPanel
labkit.ui.spec.custom

labkit.ui.view.setValue
labkit.ui.view.getValue
labkit.ui.view.setEnabled
labkit.ui.view.appendLog
labkit.ui.view.setListItems
labkit.ui.view.setListSelection
labkit.ui.view.drawImage
labkit.ui.view.resetAxes
labkit.ui.view.clearAxes
```

Existing reusable tool and diagnostic facades remain app-facing support surfaces,
but they are not part of the ordinary form/layout grammar:

```text
labkit.ui.tool.createRuntime
labkit.ui.tool.anchorEditor
labkit.ui.tool.scaleBar
labkit.ui.tool.scaleBarCalibration

labkit.ui.diag.createContext
```

These APIs are intentionally not public UI 2.0 spec constructors:

```text
labkit.ui.spec.group
labkit.ui.spec.button
labkit.ui.spec.buttonRow
labkit.ui.spec.dropdown
labkit.ui.spec.spinner
labkit.ui.spec.slider
labkit.ui.spec.edit
labkit.ui.spec.readonly
labkit.ui.spec.label
labkit.ui.spec.helpText
labkit.ui.spec.statusText
labkit.ui.spec.checkbox
labkit.ui.spec.switch
labkit.ui.spec.radioGroup
labkit.ui.spec.segmented
labkit.ui.spec.listbox
labkit.ui.spec.textarea
labkit.ui.spec.table
labkit.ui.spec.axes
labkit.ui.spec.imageAxes
labkit.ui.spec.previewAxes
labkit.ui.spec.previewPair
labkit.ui.spec.previewStack
labkit.ui.spec.logTab
labkit.ui.spec.axesControlStrip
```

`group` is excluded from v2.0 because it is too easy to turn into a hidden
layout DSL. If a later app proves a semantic grouping shape is necessary, add it
only through the public promotion rule below and do not expose row, column, flex,
span, or sizing knobs.

Final 2.0 must remove these pre-2.0 public app-facing APIs:

```text
labkit.ui.app.createShell
labkit.ui.app.tab
labkit.ui.view.section
labkit.ui.view.form
labkit.ui.view.panel
labkit.ui.view.draw
labkit.ui.view.update
labkit.ui.view.place
```

During migration, old and new APIs may coexist only to keep each PR runnable.
Do not add a compatibility bridge that makes old app calls permanent. Do not
document the old surface as supported once a migrated app family no longer
needs it.

### Spec Shape Decisions

- `labkit.ui.spec.*` constructors return data only. They must not create MATLAB
  UI handles.
- Every spec constructor returns one scalar spec struct with the common shape
  `kind`, `id`, `props`, `children`, and `slots`. Extra constructor options live
  under `props`; builders must not add ad hoc top-level fields.
- The default UI 2.0 app layout remains the LabKit workbench: `controlTabs` for
  the left control pane and `workspace` for the right preview/canvas/plot pane.
  Do not model the primary preview workspace as a normal left tab.
- `workspace` replaces old app-facing `rightGridSize`, `rightRowHeight`, and
  `rightTitle` options. Apps describe workspace content semantically; framework
  policy owns physical right-side grid rows, sizing, scroll behavior, and
  split-pane mechanics.
- Heterogeneous `children` are always represented as a cell row vector of scalar
  spec structs. `children` is `{}` when empty. Do not use MATLAB struct arrays
  for child lists, even when the current children happen to share fields.
- Slot values that contain specs are also cell row vectors. A single child in a
  slot is still wrapped in a cell so app code does not switch shape by count.
- Every control id is globally unique within one app spec. `ui.controls.<id>` is
  the primary registry path for all controls, including controls inside tabs,
  sections, workspace content, and composite families.
- Section-local paths such as `ui.sections.<sectionId>.controls.<id>` may exist
  only as aliases to the same handles. They must not create a second namespace
  that permits duplicate ids.
- `ui.controls.<id>` is a control adapter record, not necessarily a MATLAB
  primitive handle. Its internal fields are not stable public API. Stable access
  goes through semantic ids, named view helpers, and callback events.
- Duplicate ids fail at GUI-free spec validation before any GUI construction.
- Spec validation is GUI-free and belongs under reusable UI non-GUI tests.
- App authors may set semantic options such as label, items, value, enabled,
  callback, height class, and tooltip. They do not set physical grid rows,
  columns, row heights, or right-side grid sizes.
- Label width, fit/flex heights, section spacing, resize handles, scrollability,
  and preview sizing are framework policy.
- Public callbacks use `function callback(control, event)`. The semantic event
  has at least `id`, `kind`, `source`, `value`, `previousValue`, `ui`, and
  `rawEvent`. `source` is `user`, `programmatic`, or `internal`. Families may add
  fields such as `paths`, `mode`, `layout`, `viewMode`, or `action`, but they
  must not invent incompatible callback signatures.
- Programmatic view updates should not fire app-facing semantic callbacks unless
  a future helper explicitly documents that behavior.
- `custom` is the only approved path for app-specific hand-written layout in a
  migrated app. The app spec must call `labkit.ui.spec.custom(id, builder, opts)`;
  ordinary app runners and callbacks must not create grids or set
  `Layout.Row`/`Layout.Column` directly.
- The `custom` builder must be a named function in its own `.m` file with a
  top-of-file implementation contract. Inline functions, nested functions,
  anonymous builders, and local runner functions are not approved custom layout
  builders.
- A custom builder receives a framework-owned parent container, semantic id,
  context, and options; it returns a handle or struct to register at
  `ui.controls.<id>`. It may hand-write layout only inside that file.
- `custom` must not wrap ordinary controls that are covered by primitive or
  composite specs, and it must not hide parsing, calculations, export behavior,
  result schemas, or app-specific state mutation inside framework code.
- Composite controls should be modeled as small app-neutral families, not as one
  catch-all `control(type=...)` or `panel(kind=...)` API.
- A composite family owns layout, registry shape, enabled-state propagation, and
  common commands. Apps own wording, callbacks, filters, defaults, scientific
  meaning, parsing, calculation, export behavior, and result schemas.
- Prefer named modes plus a few orthogonal capability options over long lists of
  booleans. Reject invalid option combinations during spec validation.
- `field` has a fixed v2.0 kind whitelist: `text`, `number`, `spinner`,
  `dropdown`, `slider`, `checkbox`, and `readonly`. Do not allow
  `kind="custom"` or arbitrary MATLAB control names. Use `custom` for complex
  controls until repeated real app use justifies a new app shape.
- `action` is public because it represents an app command. `button` is an
  internal primitive implementation detail. v2.0 `action` fields are limited to
  id, label, onInvoke, enabled, priority, and tooltip; defer confirmation,
  busy-message, icon, color, width, and layout options until real app pressure
  proves they are needed.
- `previewArea` uses `layout` for axes arrangement and `viewModes` for
  user-facing preview choices. Do not overload `mode` for both concepts.
- Use slots for app-specific extra actions or notes inside a framework-owned
  shell. A slot may place app-supplied specs, but the app still must not set
  physical grid rows or columns.

### Composite Family Pattern

The strongest consolidation opportunity is not one giant control class and not a
primitive-constructor catalog. It is a compact workbench grammar:

1. **Workbench skeleton** captures `controlTabs`, `section`, and `workspace`.
2. **Composite families** capture repeated app shells: path selection, labeled
   fields, ranges, actions, previews, result/status panels, and logs.
3. **Internal primitives** map family implementations to MATLAB controls without
   becoming app-facing constructors.

`pathPanel` should replace separate ad hoc file pickers, file lists, folder
pickers, and output-folder panels. It should support named modes such as:

```text
singleFile
multiFile
folder
multiFolder
outputFolder
```

Its options should be app-neutral: filters, title, selection policy, list
visibility, remove/clear buttons, status text, empty text, extra actions, and
callbacks such as `onChoose`, `onRemove`, `onClear`, and `onOpenFolder`.
It should not parse files, infer experiment types, choose export names, or
encode app-specific validation beyond path kind and selection count.

Other composite families should follow the same pattern:

- `field` wraps label/help/unit/default/reset/error state around one primitive
  value control.
- `rangeField` represents paired start/end or min/max values under one semantic
  id, without encoding ROI, time-window, or color-limit business meaning.
- `action` represents an app command. It may render as a button today, but app
  code must not depend on that primitive.
- `actionGroup` owns wrapping, equal sizing, primary/secondary/destructive
  visual priority, enabled-state propagation, and command grouping.
- `previewArea` owns single/pair/stacked axes layout, optional view-mode
  selector, popout affordances, and linked axes policy. Stacked previews must
  support named axes or an axis count so waveform-style apps do not need custom
  layout just to show four synchronized axes.
- `resultTable`, `statusPanel`, and `logPanel` own common shells and empty
  states while leaving rows, wording, and updates to the app.

Do not promote a combination if its only shared part is a label beside an
app-specific algorithm control. Use `custom` or an app-local builder for those.

### Internal Primitive Inventory

The following primitive mappings may exist under private implementation files,
but app code must not call them as `labkit.ui.spec.*` constructors:

```text
action -> uibutton-like command control
field(kind="text") -> text edit field
field(kind="number") -> numeric edit field
field(kind="spinner") -> spinner
field(kind="dropdown") -> dropdown
field(kind="slider") -> slider
field(kind="checkbox") -> checkbox
field(kind="readonly") -> read-only display
pathPanel -> chooser action, list/path display, status text
resultTable -> uitable
logPanel -> text area
previewArea -> axes
statusPanel -> read-only status display
```

Do not expand this inventory into public constructors during implementation.
If a primitive becomes necessary as a public API, it must pass the public
promotion rule and be framed as a stable LabKit app shape, not a MATLAB control
wrapper.

### Public Spec Promotion Rule

A new public `labkit.ui.spec.*` family may be added only when all are true:

- it cannot be expressed cleanly by existing public families, modes, slots, or
  `custom`
- at least two real apps or one broad app family need the same app-neutral shape
- its registry behavior can be described through `ui.controls.<id>` and named
  view helpers without exposing unstable handle internals
- GUI-free validation can reject invalid specs, duplicate ids, and illegal
  option combinations where possible
- GUI structural tests can verify semantic ids, initial state, callback wiring,
  and app-neutral behavior without row/column assertions
- it does not encode app workflow, science, parser, export, plot-label, result
  schema, or log-wording semantics
- it removes app-facing layout decisions rather than hiding them in a new helper

### App UI Scan Findings

The UI 2.0 control set should be driven by the current app inventory, not only
by a theoretical control list. Current app-owned UI code repeatedly implements:

- **file list panels** in electrochem apps and image apps: open files, open
  folder, remove/clear, listbox, loaded-status text, and optional export/reload
- **single file pickers** in DIC and ECG workflows: open one typed file,
  display selected path, and optionally preview or parse it
- **output folder pickers** in image export workflows: choose folder, show
  folder, choose format, then export
- **parameter rows** across electrochem, image, DIC, and ECG apps: label plus
  spinner/dropdown/edit, optional unit text, optional reset/default, and
  consistent callback wiring
- **range rows** in ROI/time/color-limit workflows: paired start/end or min/max
  values with one semantic id
- **section action groups**: button rows or button stacks that should wrap and
  equalize without app-owned grid math
- **result/history/summary tables**: titled `uitable` areas with stable
  registry ids and fixed semantic initial states
- **log panels/tabs**: text area plus append/clear/copy/debug attachment
- **workflow notes/detail text**: app-authored text areas that should be
  layout-managed but remain app-worded
- **single, paired, and stacked preview axes**: one preview, top/bottom preview,
  and four waveform-style axes
- **axes control strips**: X/Y dropdowns, grid/legend/marker toggles, and
  optional app-provided buttons for plot refresh/swap/reset
- **preview mode selectors**: dropdown or segmented controls for original,
  processed, before/after, current pair, overlay, mask, or related modes
- **tool escape hatches**: scale-bar calibration, anchor/ROI editing, crop ROI,
  mask drawing, and image scroll/zoom runtime

No current app uses `uislider`, `uiswitch`, radio groups, trees, knobs, gauges,
or date pickers directly. `slider` belongs in the v2.0 `field` kind whitelist
because it is a common parameter presentation. `switch`, `radioGroup`,
`segmented`, `tree`, `knob`, `gauge`, date/time picker, and full color picker
stay out of the v2.0 public API until a real app proves a stable LabKit app
shape needs them.

### Framework Inclusion Tiers

Tier 1 app-neutral composite families are required for the first usable 2.0
vertical slice:

```text
pathPanel
field
rangeField
action
actionGroup
previewArea
resultTable
logPanel
statusPanel
```

Tier 2 combinations are valuable, but should wait until at least two migrated
apps need the same shape:

```text
axesControlStrip
plotOptions
historyPanel
detailsPanel
progressStatus
workflowNotes
```

Tier 3 remains app-local or `custom` unless repeated real use proves a
domain-neutral tool:

```text
DIC mask editor
crop ROI editor
curvature fit controls
ECG template controls
electrochem-specific plot annotations
image-enhancement pipeline controls
full color picker
tree browser
toolbar/context-menu systems
```

Tier promotion must follow the public spec promotion rule. Do not add a public
spec constructor merely because a MATLAB primitive exists or one app would be
slightly shorter with it.

### Current App Coverage Verdict

The app scan supports the narrowed public surface, but it also shows where UI
2.0 should measure improvement differently by app family:

| App family | Expected UI 2.0 improvement | Custom/tool boundary |
| --- | --- | --- |
| Image Match and Image Enhance | Strong canaries. File/export selectors, action groups, history/results, logs, and a single preview should migrate with custom count 0. | None expected for ordinary UI. |
| Focus Stack | Strong fit. Multi-file/folder input, processing fields, result table, log, and paired preview map directly to Tier 1 composites. | None expected for ordinary UI. |
| Batch Crop | Ordinary controls, path selection, crop parameters, preview, results, and logs improve. | Crop ROI and center/selection interaction may use `custom` or a tool. |
| Curvature | File controls, fit/export actions, parameters, results, and logs improve. | Scale-bar, anchor editor, zoom/runtime, and curve editing remain `labkit.ui.tool.*` or justified `custom`. |
| Electrochem CIC, CSC, VT, EIS, Chrono Overlay | File panels, parameter fields, action groups, results, logs, and single/pair plot workspaces improve. | Plot annotations, trim overlays, and specialized comparison behavior stay app-owned. `axesControlStrip` waits for v2.1 proof unless field/action sections become too repetitive. |
| DIC Postprocess | File pickers, overlay/enhancement fields, exports, results, log, and paired preview improve. | Advanced overlay interaction, if any, stays app-owned. |
| DIC Preprocess | Ordinary setup, options, log/detail panels, actions, and paired preview improve. | Mask, ROI, and crop editing are explicit custom/tool cases. |
| ECG Print | File import, processing fields, ROI range controls, summaries, logs, and waveform previews improve if `previewArea` supports stacked/named axes. | Waveform overlays and signal-window drawing stay app-owned rendering. |

The migration is therefore beneficial for every current app, but not because
every app becomes entirely declarative. The contract is narrower: ordinary
workbench UI must become declarative and registry-driven; domain-specific
interactions stay in app code, reusable `labkit.ui.tool.*`, or named
`labkit.ui.spec.custom` builders.

The current public list is not overdesigned relative to the inventory. The
previous risk was exposing a large primitive catalog. The revised risk profile
is:

- **Underdesign risk:** no `detailsPanel`, `historyPanel`, or
  `axesControlStrip` may leave some repeated code after the first migrations.
  Keep them Tier 2 until canary apps prove that `statusPanel`, `resultTable`,
  `field`, and `actionGroup` are awkward or duplicative.
- **Overdesign risk:** `statusPanel` could become a generic hidden panel DSL,
  `previewArea` could absorb plot-control semantics, and callback event fields
  could grow beyond the stable app contract. Guard against this by validating
  only app-neutral behavior and refusing app-specific workflow options.
- **Escape-hatch risk:** `custom` could hide ordinary form layout. Each
  migration must report custom count and reason; regular form-like apps should
  have custom count 0.

### Boundary Decisions

Reusable `+labkit` work is justified for:

- generic app shell creation from declarative app specs
- generic control tabs, sections, workspace, composite families, registries, and
  internal primitive builders
- app-neutral named view updates and rendering helpers
- app-neutral interaction lifecycle and existing tools
- diagnostics and callback instrumentation

Keep app-local:

- experiment names, labels that encode workflow wording, defaults, formulas,
  thresholds, plot annotations, result fields, export schemas, file naming, and
  alert/log wording
- DIC ROI semantics, electrochemistry result meaning, image processing
  algorithms, and wearable signal analysis
- app-specific compound control choreography unless at least two real apps prove
  that a domain-neutral tool belongs in `labkit.ui.tool`

### Benefit Gates

A UI 2.0 migration PR is not progress unless it satisfies the relevant gates:

- ordinary app UI no longer writes `uigridlayout`, `Layout.Row`,
  `Layout.Column`, `gridSize`, `rowHeight`, `rightGridSize`,
  `rightRowHeight`, or local `place(...)`
- ordinary app UI does not call internal primitive constructors such as
  `labkit.ui.spec.button`, `dropdown`, `spinner`, `slider`, `listbox`,
  `textarea`, or `axes`
- migrated callbacks update UI through registry handles and named view helpers,
  not string-action `draw`/`update`
- GUI structural tests assert semantic controls, tabs, preview axes, logs,
  callback wiring, enabled state, and debug trace plumbing; they do not assert
  exact row or column placement
- any app-owned custom UI is justified as a tool/interaction escape hatch, not
  ordinary form layout
- each migrated app reports custom usage count and reason; ordinary form-like UI
  should have custom count 0
- behavior tests still cover app-owned calculations, exports, summaries, and
  parsing separately from layout tests
- docs or scoped `AGENTS.md` updates happen only when their owned contract
  changes, but all changed contracts are reflected in the owning docs/rules
- source-string guardrails prevent migrated style debt from returning

Do not count a PR as successful if it only moves manual layout into a new helper
without reducing app-facing layout decisions.

### Migration Order

Use small, runnable, reviewable PRs. Each PR should leave the branch with a
coherent API contract and passing focused validation.

Current implementation checkpoint:

- Foundation is complete for the first implementation slice: stable spec
  constructors, `labkit.ui.app.create`, named view helpers, validation tests,
  public-surface guardrails, and docs/AGENTS/skill routing are expected to
  exist.
- The first canary is now complete on the current branch:
  `labkit_ImageMatch_app` launches through `labkit.ui.app.create`, uses the
  declarative workbench, and no longer carries ordinary old-UI layout code.
- The image-editor pair is now complete on the current branch:
  `labkit_ImageEnhance_app` also launches through `labkit.ui.app.create` and
  confirms that ordinary image-app UI can stay within the current stable spec
  surface without promoting new primitives.
- The next broader image-app slice is now complete on the current branch:
  `labkit_FocusStack_app` also launches through `labkit.ui.app.create`,
  confirms that paired preview workspaces fit the stable grammar, and keeps
  ordinary UI custom count at 0.
- Canary-driven framework additions now in use are:
  `pathPanel.selectionMode`, `pathPanel.onSelectionChange`, and
  `previewArea.onModeChange`.
- Focus Stack also confirms the preferred file-panel composition: use
  `pathPanel` for chooser/list/count behavior and add adjacent actions such as
  `Open image folder` only when the workflow genuinely needs a second load
  path. Do not grow a separate public file-panel family yet.
- The next migration slice should stay in image measurement with
  `labkit_BatchImageCrop_app`, because it exercises the first justified
  custom/tool-heavy preview interaction while leaving ordinary controls
  declarative.

1. **Spec grammar and validation**
   - Complete in the current foundation checkpoint. Future changes should be
     narrow fixes, not a second planning pass.
   - Add only the stable minimal public spec constructors and validation.
   - Add private/internal primitive builders for `field`, `action`,
     `pathPanel`, `previewArea`, `resultTable`, `logPanel`, and `statusPanel`.
   - Add duplicate-id, callback event, field-kind whitelist, invalid-option, and
     default-policy tests under existing `testLabkitUi`.
   - Update project public-surface guardrails to allow the new `+spec` package
     while rejecting public primitive constructor drift.
   - Do not migrate apps yet.

2. **Vertical app builder slice**
   - Complete in the current foundation checkpoint. Future changes should be
     driven by canary migration evidence.
   - Add `labkit.ui.app.create` for `controlTabs`, sections, workspace,
     composite families, registries, debug context, and basic resize policy.
   - Add named view helpers needed by one canary app.
   - Use reusable UI GUI tests to verify semantic registry, callback wiring,
     preview/log handles, and debug integration.

3. **Canary app migration**
   - Complete on the current branch with `labkit_ImageMatch_app`, because it is
     recent, regular, and exposes the local
     `place(...)`/preview-boilerplate style debt clearly.
   - Keep app calculations, state, export, image IO, and wording app-local.
   - Update only the image-measurement GUI structural contract needed for the
     canary.
   - Prove ordinary UI needs no public primitive constructors and custom
     count 0.
   - Keep a canary guardrail that prevents new old-style calls in the migrated
     path.

4. **Image editor pair**
   - Complete on the current branch with `labkit_ImageEnhance_app`.
   - Consolidate any API gaps revealed by the first two image apps before
     migrating broad app families.
   - Update `docs/ui.md`, `docs/apps.md`, `+labkit/AGENTS.md`, `apps/AGENTS.md`,
     and relevant skills to state that new UI work uses the declarative API.
     Mark old APIs as migration-only, not supported style.

5. **Regular electrochemistry apps**
   - Migrate CIC and VT Resistance together only if the shared top/bottom plot
     pattern is already covered by public composites, internal primitives, or
     approved custom tools; otherwise split them.
   - Migrate CSC separately because curve comparison controls differ.
   - Migrate EIS and Chrono Overlay after the single-axis and two-axis preview
     patterns are stable.
   - Preserve DTA facade use, calculations, exports, plot labels, and CSV
     schemas.

6. **DIC and complex image apps**
   - Migrate DIC Preprocess and DIC Postprocess using spec for ordinary
     controls and `custom`/tool surfaces for ROI, mask, crop, and paired-preview
     interactions.
   - Focus Stack is complete on the current branch. Migrate Batch Crop and
     Curvature after the crop/selection custom boundary stays explicit and
     scale-bar/anchor-editor/tool patterns remain app-owned.
   - Do not generalize image algorithms into `+labkit`.

7. **Wearable app**
   - Migrate ECG Print after tables, waveform previews, and signal-summary
     controls are represented cleanly.
   - Preserve `labkit.biosignal.*` usage and app-owned export/summary behavior.

8. **Public-surface removal**
   - Delete pre-2.0 public UI API files after all app and test callers are
     migrated.
   - Update `PackagePublicSurfaceTest`, `ProjectStructureGuardrailTest`,
     architecture helpers, docs, scoped `AGENTS.md`, and skills in the same PR.
   - Add hard-fail guardrails for old calls and manual app layout mechanics.

9. **Ledger retirement**
   - Remove this active UI 2.0 section or shrink it to a short historical
     invariant after the old API surface and temporary allowlists are gone.

### Guardrail Plan

Use staged guardrails so the branch remains useful throughout migration:

- Early: allow old UI APIs only outside migrated canary paths; fail if migrated
  apps call old APIs.
- Middle: maintain a shrinking allowlist of app families that still call
  pre-2.0 APIs. The allowlist must be in project guardrails, not hidden in prose
  alone.
- Final: hard-fail all app-owned calls to `createShell`, `tab`, `section`,
  `form`, `panel`, `draw`, `update`, `place`, `rightGridSize`,
  `rightRowHeight`, `resizeRows`, direct `Layout.Row`, direct `Layout.Column`,
  and local `place(...)`, except in approved `custom`/tool implementation
  files.
- Public-surface tests must require the target 2.0 API list and reject helper
  dump packages such as `+labkit/+ui/+control`.
- Public-surface tests must reject app-facing primitive spec constructors unless
  a later design review explicitly promotes one through the public spec
  promotion rule.
- Canary-family guardrails should report custom usage count and fail ordinary
  form-like custom usage in migrated paths.
- Documentation guardrails must prevent scoped agent rules from recommending
  deleted UI APIs.

### Validation Plan

Do not create a parallel runner just for UI 2.0. Use existing build tasks unless
a later implementation proves that a new task is necessary and updates
`buildfile.m`, `docs/testing.md`, scripts, and build-task guardrails together.

Use:

```text
buildtool testLabkitUi
buildtool testLabkitUiGui
buildtool testAppsImageMeasurementGui
buildtool testAppsElectrochemGui
buildtool testAppsDicGui
buildtool testAppsWearableGui
buildtool testAppsGui
buildtool testAppsSmokeGui
buildtool testProject
buildtool test
```

Validation routing:

- spec constructors, callback event contract, field kind whitelist, custom
  builder validation, and promotion guardrails: `testLabkitUi`
- app builder, layout policy, registry, resize, preview, log, diagnostics:
  `testLabkitUiGui`
- canary and app-family migrations: affected app-family GUI task plus
  `testAppsSmokeGui`
- public surface, no-legacy, no-manual-layout, docs/AGENTS/skill routing:
  `testProject`
- broad API removal: `testLabkitUiGui`, `testAppsGui`, `testAppsSmokeGui`,
  `testProject`, and default `test`

CI status checks after a push should be low-noise. Before reading the new run
status, inspect the most recent successful run for the same workflow/branch,
compute its total elapsed duration, and wait at least that long. Use that
duration as the minimum interval between later status reads unless a job has
already failed and logs are needed for a fix.

Automated GUI tests remain structural. Interactive file selection, real drawing,
visual quality, and full workflow feel require manual MATLAB GUI validation.

### Documentation And Skill Sync

Update each documentation surface when its owned contract changes:

- `docs/ui.md`: rewrite when `app.create`, `spec.*`, named view helpers, custom
  escape hatches, and the final public surface are implemented. It now
  documents the implemented UI 2.0 foundation plus migration-era legacy APIs;
  keep it current as app migrations remove old surface, but do not expand it
  into a second migration roadmap.
- `docs/architecture.md`: update when the official app-facing UI surface
  changes from pre-2.0 layered construction to declarative construction.
- `docs/apps.md`: update when app entrypoint guidance changes to
  `labkit.ui.app.create`.
- `docs/testing.md`: update only if validation routing, task names, or GUI test
  semantics change.
- `AGENTS.md`, `+labkit/AGENTS.md`, `apps/AGENTS.md`, and `tests/AGENTS.md`:
  update when agent routing or ownership rules change.
- Repo skills: update `labkit-app-builder`, `labkit-boundary-guard`, and
  `labkit-test-planner` guidance when the new UI API becomes the default for
  new or migrated UI work while preserving legacy routing for unmigrated app
  maintenance.

Do not update human docs with future-tense roadmap text. They should describe
the current project behavior once the corresponding implementation lands.

### Completion Criteria

The UI 2.0 migration is complete only when:

- all supported app entry points launch through `labkit.ui.app.create`
- all ordinary app UI is declared through the stable minimal
  `labkit.ui.spec.*` surface
- all migrated controls, sections, tabs, preview axes, and logs are reachable
  through semantic registries
- no app-owned ordinary UI code uses direct grid row/column mechanics
- no app-owned ordinary UI code calls pre-2.0 UI public APIs
- no app-owned ordinary UI code calls internal primitive spec constructors
- custom builders are limited to documented compound interactions and every
  remaining custom use has a reason
- old public API files are deleted or made private implementation details that
  apps cannot call
- public-surface and no-legacy guardrails enforce the new contract
- docs, scoped `AGENTS.md`, and repo skills no longer recommend deleted APIs
- focused and broad automated validation pass, with manual GUI checks called
  out for interactive workflows
- this ledger no longer carries an active UI 2.0 roadmap section

## Migration Standard

Apps are first-class products. `+labkit` stays a small domain-neutral foundation
with UI, DTA, and biosignal facades. App-specific calculations, summaries,
plots, exports, workflow wording, file conventions, and result schemas stay
under the owning app tree.

A healthy runner owns orchestration only: launch/debug wiring, shell assembly,
state coordination, callback registration, alerts, log wording, and refresh
ordering.

Extract only behavior that becomes clearer and directly testable, and only when
the real GUI path calls the extracted helper. Use app-owned packages for
app-specific deterministic behavior. Use `labkit-boundary-guard` before moving
anything into `+labkit`.

Do not create new app `private` runners, root legacy command wrappers,
`*Workflow.m` adapters, app `+core/dispatch.m` routers, or convenience public
packages such as `+labkit/+analysis`, `+io`, `+data`, or `+util`.

## Future Debt Rules

- If guardrails detect new migration debt, update the matching expected-debt
  inventory, this ledger, and the affected source or tests together.
- If debt inventory is empty, prefer shrinking this ledger over adding roadmap
  prose, scripts, or new governance layers.
- Keep completed migrations as historical baselines only when they clarify a
  current guardrail invariant.
- Use `labkit-test-planner` for validation routing and `docs/testing.md` for
  exact commands.
- After any completion push, inspect CI. If required CI fails, read only failing
  job logs, fix the cause, rerun the relevant local check, push again, and
  repeat until CI passes or an infrastructure/access blocker is explicit.
