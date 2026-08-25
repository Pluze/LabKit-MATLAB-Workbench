# LabKit Library Rules

`+labkit` is the reusable foundation. It must stay smaller and more stable
than the apps that consume it.

## Read before editing

Read `docs/develop/app-authoring/architecture.md`, the affected source and
tests, and the one owning manual:

- UI: `docs/develop/framework/README.md`
- image: `docs/develop/libraries/image/README.md`
- thermal: `docs/develop/libraries/thermal/README.md`
- DTA: `docs/develop/libraries/dta/README.md`
- RHS: `docs/develop/libraries/rhs/README.md`
- biosignal: `docs/develop/libraries/biosignal/README.md`
- Mark-10: `docs/develop/libraries/mark10/README.md`

Library behavior specifications mirror the package below
`tests/specs/labkit/<area>/`.
Use `labkittest.explain` to find the exact owner and contract.

## Ownership

- Promote an API only when it is domain-neutral, independently testable, and
  useful beyond one app workflow. Duplication or line-count reduction is not
  sufficient.
- New public names are the last resort. First keep product behavior App-local;
  then prefer a cohesive option, method, or operation on an existing focused
  contract; then prefer private adapter/runtime support when Apps need not
  call it. Add a public name only for stable multi-App use or when extending
  the nearest API would make that API an ambiguous bucket.
- Keep experiment formulas, thresholds, units, result schemas, plot wording,
  exports, file queues, and workflow decisions in apps.
- Do not add public helper-dump packages such as `analysis`, `data`, `io`, or
  `util`.
- `labkit.image`, `thermal`, `dta`, `rhs`, `biosignal`, and `mark10` stay GUI-free and
  app-free. Each owns its documented file/data/scientific primitive contract,
  not an app's task orchestration.
- `labkit.app` owns the App SDK. Registry mutation, queueing, concrete
  controls, native adapters, and lifecycle handles remain private.
- Shared image utilities retain native pixels by default. A finite preview
  budget is an explicit caller-owned product decision, not a facade default.
- `labkit.contract` owns MATLAB-native version requirements and range checks,
  not app discovery or package management.
- Do not introduce MATLAB classes or a third-party runtime dependency without
  explicit approval.
- The App SDK is a stable composition-only contract: no public inheritance
  hierarchy, mutable handle-state model, version-named namespace, or adapter
  back to retired author-facing transport structs.

## Runtime contracts

- Apps return one `labkit.app.Definition` and launch it through
  `Definition.launch`. The runtime owns
  startup readiness, busy state, queued events, atomic presentation, close
  guards, diagnostics, resources, and interactions.
- Semantic ids are developer-owned and framework-validated. App ids are stable
  compatibility identifiers; layout/action/axis/source namespaces must remain
  legal and unique; references must resolve before UI mutation. Bind paths are
  opaque App-owned field paths, not framework-owned project/session schemas.
- View snapshots must preserve unchanged graphics and viewports. Renderers own
  incremental overlay changes; interaction specs own user gestures.
- Establish the legal domain of interdependent native properties before
  assigning dependent values; constructor name-value order is not a contract
  across MATLAB releases. Give responsive resize to one explicit container
  owner and verify release-sensitive layout through native construction.
- Show determinate progress only when work has a measurable denominator.
  Otherwise report real named stages, and paint the stage before synchronous
  expensive work.
- One interaction target has one active gesture owner. A managed movable
  rectangle accepts movement from its visible box or interior, not only a thin
  edge; display-only affordances remain non-pickable.
- The App runtime composes complete `labkit.app.view.Snapshot` values from
  `labkit.app.layout.*` defaults, strict state bindings, framework-owned state,
  and the App's dynamic view fragment; private reconciliation owns diffs.
- Layout controls own direct function-handle callbacks and plot renderers.
  Definition privately compiles those links; Apps never maintain a second
  handler, renderer, or capability registry. File-list source and selection
  lifecycle is binding-driven rather than mirrored by App callbacks.
- App examples do not relay SDK values through untyped app-local parameters.
  Runtime callbacks name the complete application state, concrete event
  payload, and `CallbackContext` at their boundary, then delegate domain work
  through narrow explicit inputs.
- Compile the immutable static Definition graph once. View commits
  validate against the cached graph and must not re-flatten layout on every
  update.
- A new public UI capability needs repeated evidence from at least two Apps or
  one framework-owned lifecycle/consistency requirement. Prefer framework
  automation when repeated App callback or presenter glue is the evidence.
- Do not interpret framework ownership as requiring a public function.
  Lifecycle, reconciliation, layout, and native behavior normally remain
  internal unless App authors need a clear stable contract.
- The framework does not own task archives, generic save/load callbacks,
  document identities, dirty tracking, recovery files, migration loops, or
  source relinking, project schemas, or generic result manifests. Definition
  accepts only opaque in-memory App state; session journals record operations
  and failures but do not serialize App state.
- An App with a real continuation workflow owns its explicit save/open
  controls and the complete JSON, CSV, or MAT archive contract, including
  fields, compatibility, source lookup, and resume semantics. Save one current
  final-state snapshot; do not encode interaction history or intermediate
  adjustments unless history is itself an explicit product requirement.
- Do not keep old and current fields on one live facade value. Migrate consumers
  together, express the breaking facade range, and remove aliases as one
  change. Defaults apply only to omitted options; an explicitly unknown
  scientific mode fails rather than selecting a plausible fallback.
- Resource replacement for the same id is intentional and idempotent; use
  distinct ids for resources that coexist and remove them at the App-owned
  workflow boundary when they should not survive until close.
- Diagnostic output must stay app-neutral and sanitized.

## API and release contract

- Every non-private public function documents syntax, inputs, outputs, options,
  defaults, legal values, errors, and related APIs immediately after its
  declaration. `Example:` blocks are executable; file-dependent sketches use
  `Typical Call:`.
- Private helpers document caller, shapes, side effects, and assumptions.
- An app-facing facade change updates its `version.m`, current owning manual,
  and one lightweight structured change record before its task-branch PR is
  merge-ready.

## Validation

Use `labkittest.run(File=...)` to select the affected `labkit/<area>` owner and
add downstream app-family or hidden-GUI coverage when the app-facing contract
can change. Package boundary and public-surface changes also run project
guardrails. Exact commands belong in
`docs/maintain/testing.md`.
