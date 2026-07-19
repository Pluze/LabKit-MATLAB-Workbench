# LabKit Library Rules

`+labkit` is the reusable foundation. It must stay smaller and more stable
than the apps that consume it.

## Read before editing

Read `docs/development/build-apps/architecture.md`, the affected source and
tests, and the one owning manual:

- UI: `docs/framework/README.md`
- image: `docs/libraries/image/README.md`
- thermal: `docs/libraries/thermal/README.md`
- DTA: `docs/libraries/dta/README.md`
- RHS: `docs/libraries/rhs/README.md`
- biosignal: `docs/libraries/biosignal/README.md`

Framework tests live under `tests/cases/unit/labkit_framework/` and
`tests/cases/gui/labkit_framework/`.

## Ownership

- Promote an API only when it is domain-neutral, independently testable, and
  useful beyond one app workflow. Duplication or line-count reduction is not
  sufficient.
- Keep experiment formulas, thresholds, units, result schemas, plot wording,
  exports, file queues, and workflow decisions in apps.
- Do not add public helper-dump packages such as `analysis`, `data`, `io`, or
  `util`.
- `labkit.image`, `thermal`, `dta`, `rhs`, and `biosignal` stay GUI-free and
  app-free. Each owns its documented file/data/scientific primitive contract,
  not an app's task orchestration.
- `labkit.app` owns the future App SDK; `labkit.ui` stays parser- and
  analysis-free while its legacy public layers are
  `runtime`, `layout`, `plot`, `interaction`, and `debug`; registry mutation,
  queueing, concrete controls, and lifecycle handles remain private.
- `labkit.contract` owns MATLAB-native version requirements and range checks,
  not app discovery or package management.
- Do not introduce MATLAB classes or a third-party runtime dependency without
  explicit approval.
- The active UI explicit-contract migration has Phase 1 approval for the small
  sealed immutable value vocabulary accepted in
  `.agents/migration/ui-explicit-contract/phase-1-contract-rfc.md`. Keep it
  composition-only: no public inheritance hierarchy, mutable handle-state
  model, version-named namespace, or adapter back to retired transport
  structs. Phase 2 may implement the production kernel, but do not release the
  contract until its own compile/help/error gate passes.

## Runtime contracts

- Migrated Apps return one `labkit.app.Definition` and launch it through
  `Definition.launch`; do not adapt explicit values back into
  `labkit.ui.runtime.launch/define`. The runtime owns
  startup readiness, busy state, queued events, atomic presentation, close
  guards, diagnostics, persistence, recovery, resources, and interactions.
- Semantic ids are developer-owned and framework-validated. App ids are stable
  compatibility identifiers; layout/action/axis/source/result namespaces must
  remain legal and unique; references must resolve before UI mutation.
- View snapshots must preserve unchanged graphics and viewports. Renderers own
  incremental overlay changes; interaction specs own user gestures.
- The App runtime composes complete `labkit.app.view.Snapshot` values from
  `labkit.app.layout.*` defaults, strict state bindings, framework-owned state,
  and the App's dynamic view fragment; private reconciliation owns diffs.
- Layout signals reference `labkit.app.StateHandler` values and Definition
  collects them. `ExtraHandlers` is only for programmatic dispatch. Ordinary
  Apps omit the capability list; `StrictCapabilities` is advanced audit
  metadata.
- App examples do not relay SDK values through untyped app-local parameters.
  Layout builders obtain the handlers they reference; runtime-injected
  contexts and event payloads use concrete types in callback `arguments`
  blocks.
- Compile the immutable static Definition graph once. View commits
  validate against the cached graph and must not re-flatten layout on every
  update.
- A new public UI capability needs repeated evidence from at least two Apps or
  one framework-owned lifecycle/consistency requirement. Prefer framework
  automation when repeated App callback or presenter glue is the evidence.
- Persistence writes only the current project envelope. Ordered app migrations
  and declared legacy importers are read-only compatibility hooks and must not
  introduce app-id branches in the framework.
- Resource replacement for the same scope and id is intentional and
  idempotent; use distinct ids for resources that coexist.
- Diagnostic output must stay app-neutral and sanitized.

## API and release contract

- Every non-private public function documents syntax, inputs, outputs, options,
  defaults, legal values, errors, and related APIs immediately after its
  declaration. `Example:` blocks are executable; file-dependent sketches use
  `Typical Call:`.
- Private helpers document caller, shapes, side effects, and assumptions.
- An app-facing facade change updates its `version.m`, owning manual, and one
  component history record before direct-main push or merge.

## Validation

Use the affected `labkit_framework/<area>` suite and add downstream app-family
or hidden-GUI coverage when the app-facing contract can change. Package
boundary and public-surface changes also run project guardrails. Exact commands
belong in `docs/development/maintain-and-release/testing.md`.
