# Agent Migration Ledger

This is the agent-facing migration debt ledger for LabKit. It is not an
architecture manual, validation matrix, historical changelog, or roadmap.

Human-facing architecture and app behavior live in `docs/`. Exact validation
commands live in `docs/testing.md` and are routed through
`labkit-test-planner`. This ledger owns only active migration debt facts,
retirement rules, and the minimum standard for handling future migration debt.

## Lifecycle

Update this ledger only when migration debt is added, reduced, retired, or
reprioritized. Keep it aligned with:

- current capability-style project guardrails
- `AppPackageStructureGuardrailTest` app package structure checks
- `docs/architecture.md` when human-facing boundary facts change

When debt is retired, remove stale ledger entries and shrink this file in the
same change. A completed migration should not remain as active roadmap text.

## Current Debt Snapshot

Current active migration debt:

```text
GUI workflow acceptance validation migration
```

Current facts:

- Tracked files over the 650-line repository file budget: `labkit_launcher.m`
  only, by design, because it is the self-contained repair entry point.
- App entry points and package-root app `run.m` runners are covered by the
  repository file budget rather than a separate app-only line limit.
- App `private/` debt: none.
- `+labkit` private helper contract debt: none.
- String-dispatch workflow adapters and app `+core/dispatch.m` routers: none.
- No active runner maps exist.
- Supported app entry points launch through `labkit.ui.app.create` directly or
  through app-owned package-root `run.m` orchestration.
- Apps keep ordinary data-only specs in
  `+<app_slug>/+ui/buildSpec.m`, route extracted production code through
  role-based app-owned component packages, and avoid generic helper buckets.
- The public app-facing UI surface is the layered
  `labkit.ui.app/spec/view/tool/diag` foundation documented in `docs/ui.md`.
- App-owned save dialogs that need safe default-folder handling use
  `labkit.ui.app.promptOutputFile`; ordinary file input selection is represented
  as file entries through `labkit.ui.spec.filePanel`.
- Image workflow apps keep run/export/measurement task snapshots and
  deterministic fingerprints under app-owned `+state` helpers.
- `buildtool gui` already runs hidden noninteractive MATLAB GUI tests through
  the official runner and must remain the public broad GUI validation entry
  point.
- Current app GUI tests are mostly launch, layout, callback, and debug-trace
  checks; they do not yet consistently prove that each app can complete its
  core user task flow with synthetic inputs and exports.

## Active Route: GUI Workflow Acceptance Validation

Objective:

Migrate app-level GUI validation from mostly structural launch/layout checks to
hidden, synthetic-data workflow acceptance checks that prove a user can complete
each app's core task flow. The target is not scientific correctness proof.
Correctness stays in app-owned GUI-free unit tests. Workflow GUI tests should
expose broken flows, state-machine errors, modal-dialog stalls, basic
performance regressions, reload/reset/idempotency bugs, and export-path
failures.

Target shape:

- Keep the official MATLAB test framework and build tasks. Do not create a
  parallel runner, custom pass/fail tree, or app-specific test command surface.
- Keep `buildtool gui` hidden by default. Workflow acceptance tests must create
  real MATLAB figures, controls, callbacks, and layout trees while avoiding
  visible windows and blocking OS dialogs.
- Add a small `tests/shared` semantic GUI workflow driver only for
  app-neutral mechanics such as reading the `labkitUiRegistry`, invoking
  semantic actions, injecting `filePanel` dialog providers, checking enabled
  state, reading status text, and counting preview children.
- Keep synthetic fixture generation, expected workflow sequence, performance
  budget, export assertions, and result-schema expectations in the owning app's
  tests.
- Use app-owned runner hooks only where workflow tests need to replace modal or
  OS-bound edges such as alerts, input dialogs, output-folder choosers, and save
  prompts. These hooks are test infrastructure for app-owned workflows, not a
  new public `+labkit` API.
- Let completed app workflow tests absorb smoke-launch coverage for that app
  and most low-value exact layout assertions. Keep only essential structural
  checks for semantic controls, standard shell shape, debug trace, and visible
  commands that are not exercised by the workflow.
- Keep framework GUI tests under `tests/cases/gui/labkit/` and gesture tests
  under `tests/cases/gui/gesture/`; app workflow acceptance does not replace
  reusable UI, busy-state, filePanel, debug, runtime, drag, scroll, or tool
  lifecycle coverage.
- Keep app request compatibility and framework API return-shape checks in
  contract/unit suites. Workflow GUI tests consume those contracts; they do not
  replace them.

Migration workstreams:

1. Define the shared workflow-driver helper in `tests/shared/` with explicit,
   semantic operations. Avoid vague helpers that guess app meaning from button
   labels or combine unrelated concepts such as status text and selected-list
   text.
2. Add the first representative app workflow tests for at least one image app,
   one electrochem/DTA app, and one large-file or biosignal/RHS app. Start with
   CI-sized synthetic inputs, then record which app families merit larger
   manual or scheduled stress cases.
3. Add app-owned hooks only when a real workflow path otherwise opens a modal
   alert, OS file chooser, or output chooser that would stall hidden GUI tests.
   Keep normal public app entry points unchanged.
4. Extend test tags and build routing only after the first workflow tests prove
   the shape. Candidate tags are `Workflow` for default hidden acceptance and
   `Stress` for larger manual or scheduled runs.
5. For each app that gains workflow acceptance, shrink or merge its
   `GuiLayout*Test` coverage to non-duplicated structural checks, and stop
   relying on `AppLaunchGuiTest` as that app's primary smoke coverage.
6. When every supported app has workflow acceptance coverage, convert
   `AppLaunchGuiTest` into a guardrail that fails only for apps missing
   dedicated workflow or structural GUI coverage.
7. Update `docs/testing.md` and `tests/AGENTS.md` when the validation contract
   changes from structural-only wording to the final structural/workflow/gesture
   split. Do not update user-facing app docs for internal test hooks.

Non-goals:

- Do not verify scientific validity or complete visual quality through GUI
  workflow acceptance tests.
- Do not move app-specific workflow, synthetic data semantics, performance
  thresholds, export schemas, or result assertions into `+labkit`.
- Do not make OS-coordinate mouse automation the primary test mechanism.
- Do not require every app to run large stress scenarios in default CI.
- Do not preserve exact component counts when semantic workflow and key control
  assertions cover the same risk with less brittleness.

Validation gates:

- Prototype and migration changes must run through the affected app GUI suite
  first, then the source-aligned `buildtool changed` or relevant
  `runLabKitTests("Suites", ...)` scope.
- Before broad handoff, `buildtool gui` must still run hidden by default and
  include workflow acceptance without stealing focus.
- Any routing, tag, or validation-policy change must update the project build
  guardrails that check known tags, task catalog shape, and GUI hidden mode.

Completion criteria:

- Each supported app has at least one hidden workflow acceptance test covering
  launch, synthetic input load, core action, state update, and export or task
  completion artifact.
- Representative robustness paths cover cancel/reload/reset/idempotent export
  where applicable.
- App-level structural GUI tests no longer duplicate workflow coverage through
  brittle exact component counts unless that exact structure is the behavior
  under test.
- `AppLaunchGuiTest` is retired as broad smoke coverage or narrowed to a
  missing-coverage guardrail.
- Framework UI, gesture, contract, and GUI-free unit tests remain in their
  current ownership lanes.
- This active route is removed or shrunk to a compact debt-free ledger once the
  migration is complete.

## Migration Standard

Apps are first-class products. `+labkit` stays a small domain-neutral foundation
with UI, DTA, RHS, and biosignal facades. App-specific calculations, summaries,
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

- If guardrails detect new migration debt, update this ledger and the affected
  source or tests together.
- If debt inventory is empty, prefer shrinking this ledger over adding roadmap
  prose, scripts, or new governance layers.
- Keep completed migrations as historical baselines only when they clarify a
  current guardrail invariant.
- Use `labkit-test-planner` for validation routing and `docs/testing.md` for
  exact commands.
