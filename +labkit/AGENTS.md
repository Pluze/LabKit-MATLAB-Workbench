# LabKit Library Rules

`+labkit` is the reusable foundation. It must stay smaller and more stable
than the apps that consume it.

## Read before editing

Read `docs/development/architecture.md`, the affected source and tests, and the
one owning manual:

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
- `labkit.ui` stays parser- and analysis-free. Its public layers are
  `runtime`, `layout`, `plot`, `interaction`, and `debug`; registry mutation,
  queueing, concrete controls, and lifecycle handles remain private.
- `labkit.contract` owns MATLAB-native version requirements and range checks,
  not app discovery or package management.
- Do not introduce MATLAB classes or a third-party runtime dependency without
  explicit approval.

## Runtime contracts

- Apps launch through `labkit.ui.runtime.launch/define`. The runtime owns
  startup readiness, busy state, queued events, atomic presentation, close
  guards, diagnostics, persistence, recovery, resources, and interactions.
- Semantic ids are developer-owned and framework-validated. App ids are stable
  compatibility identifiers; layout/action/axis/source/result namespaces must
  remain legal and unique; references must resolve before UI mutation.
- Presentation must preserve unchanged graphics and viewports. Renderers own
  incremental overlay changes; interaction specs own user gestures.
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
