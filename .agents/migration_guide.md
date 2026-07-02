# Agent Migration Ledger

This is the agent-facing migration debt ledger for LabKit. It is not an
architecture manual, validation matrix, historical changelog, or general
roadmap.

Human-facing architecture and app behavior live in `docs/`. Exact validation
commands live in `docs/testing.md` and are routed through
`labkit-test-planner`. This ledger owns active migration debt facts, retirement
rules, and executable migration routes.

## How To Use This File

Use this file when working on migration debt, runner complexity, helper
structure, app workflow validation, app-owned package cleanup, or framework
hook extraction. A capable agent should be able to continue an active route
from this file without asking for a new plan.

Before executing a route:

1. Verify the current facts with source scans. Do not trust this snapshot if
   files have changed.
2. Preserve app-first ownership: app workflow stays in apps; reusable mechanics
   move to `+labkit` only when the boundary test is clearly met.
3. Prefer behavior-backed refactors. A line-count drop is not progress unless
   responsibilities become clearer and the real GUI or app path calls the
   extracted helper.
4. Update this file only when migration debt is added, reduced, retired, or
   reprioritized.

When a route completes, shrink this file again. Completed work should become
source, tests, docs, or guardrails, not permanent roadmap prose.

## Current Debt Snapshot

Last audited: 2026-07-02.

Current active migration debt:

```text
test performance compression route
```

Current facts:

- MATLAB source inventory from current working-tree files:
  - total: 767 `.m` files, 66,325 lines across `apps/`, `+labkit/`, and `tests/`
  - `apps/`: 430 files, 28,455 lines, max 649 lines
  - `+labkit/`: 206 files, 18,878 lines, max 649 lines
  - `tests/`: 131 files, 18,992 lines, max 649 lines
  - `labkit_launcher.m`: 1,700 lines and intentionally exempt
- Tracked files over the 650-line repository file budget:
  `labkit_launcher.m` only, by design, because it is the self-contained repair
  entry point.
- Package-root app `run.m` files currently remain within budget. Budget
  watchlist files are:
  - `apps/image_measurement/batch_crop/+batch_crop/run.m` at 649 lines
  - `apps/image_measurement/flir_thermal/+flir_thermal/run.m` at 648 lines
  - `apps/neurophysiology/rhs_preview/+rhs_preview/run.m` at 648 lines
  - `apps/image_measurement/image_enhance/+image_enhance/run.m` at 642 lines
  - `apps/image_measurement/image_match/+image_match/run.m` at 563 lines
  These are not active migration debt by line count alone. They are
  change-control triggers: do not add unrelated behavior to them without a
  responsibility audit or a cohesive app-owned extraction.
- `+labkit` implementation hotspots near the file budget are:
  - `+labkit/+ui/+diag/createContext.m` at 649 lines
  - `+labkit/+ui/+tool/createRuntime.m` at 636 lines
  - `+labkit/+biosignal/private/detectEcgPeaksImpl.m` at 623 lines
  - `+labkit/+ui/+app/private/buildFilePanelControl.m` at 607 lines
  - `+labkit/+ui/+app/private/buildControl.m` at 539 lines
- Debug sample packs are complete and no longer an active migration route:
  each supported app owns its generator under the app tree, debug launch writes
  clean-room samples/manifests under `artifacts/debug/.../<SessionId>/`, and
  debug startup remains otherwise empty.
- Helper-quality audit is a dry-run routing aid, not a blocking guardrail:
  use `labkitHelperQualityAudit(root, "MaxLines", 20, "Scope", "all")` to
  identify new tiny-helper review candidates when related code is touched.
  Preserve legitimate small contracts such as public facades, state factories,
  input policies, export/dialog side effects, UI adapters, test APIs,
  framework adapters, and tested multi-call helpers.
- Current app `private/` debt, `+labkit` private helper contract debt, and
  string-dispatch/core-router migration debt are all clear.
- Supported app entry points launch through `labkit.ui.app.create` directly or
  app-owned package-root `run.m` orchestration. App specs stay in
  `+<app_slug>/+ui/buildSpec.m`; production behavior should route through
  role-based app-owned component packages, not generic helper buckets.
- Shared mechanics already owned by `+labkit` include the layered
  `labkit.ui.app/spec/view/tool/diag` surface, image facade primitives,
  file-entry path/index helpers, output prompts, hidden-test-safe alerts,
  debug exception reporting, and close guards. App-specific formulas,
  workflow wording, task snapshots, plotting, and export schemas stay app-owned.
- GUI workflow coverage is now real-workflow-first. `AppLaunchGuiTest` is a
  missing-coverage guardrail; do not re-expand structural GUI tests with
  launch-only assertions already covered by workflow tests or shared debug
  tests.
- Test performance profiling on 2026-07-02 showed two actionable timing
  layers:
  - GUI suite discovery/list-only took about 5.28 seconds inside MATLAB
    profiler capture, with `runLabKitTests>discoverOfficialGroups` around
    3.72 seconds and `setupLabKitTestPath` around 1.33 seconds.
  - `GuiLayoutUiDeclarativeAppTest/test_gui_layout_ui_declarative_app` took
    about 15 seconds of test execution, with fixed `settleLayout` waits
    contributing about 2.32 seconds and app/workspace/preview construction
    contributing about 3.44 seconds.

## Reopen Triggers

Open a new active route here only when current scans expose concrete debt:

- an app `run.m` exceeds the 650-line hard budget, or a substantive change
  would add unrelated behavior to a budget-watchlist runner without a
  responsibility audit
- `labkitHelperQualityAudit(root, "MaxLines", 20)` reports new
  `inline-or-merge-candidate` rows after excluding valid contracts such as
  app entrypoints, `requirements.m`, `version.m`, `+ui/buildSpec.m`, state
  factories, input policies, test APIs, framework adapters, and
  `+export/write*.m` side-effect boundaries
- a new app entry point appears without dedicated GUI coverage, causing the
  `AppLaunchGuiTest` coverage guardrail to fail
- hidden workflow validation needs a new app-neutral driver operation or a new
  app-owned test hook to avoid a blocking OS/modal dialog
- a migration exposes package-boundary drift that cannot be fixed locally
  without a new `+labkit` API decision

## Active Route: Test Performance Compression

Goal Prompt:

Compress LabKit validation wall-clock time without weakening the behavior
contracts that make the GUI app workbench safe to change.

Objective:

- Reduce local edit-loop time, full GUI suite wall-clock time, and CI time
  separately. Do not optimize one by making the others less trustworthy.
- Use current profile artifacts, JUnit timing, and GitHub Actions step timing
  as evidence before changing runner structure.
- Keep build tasks and `docs/testing.md` as the human command surface; this
  route owns only the active migration work and agent execution state.

Operating principles:

- Measure first, then change the narrow slow path that the data proves.
- Preserve existing app workflow coverage unless an equivalent or stronger
  app-owned unit, integration, or focused GUI test replaces the same contract.
- Prefer event-driven waits, deterministic shard selection, and test metadata
  over fixed sleeps and hard-coded class lists.
- Follow large-project test strategy patterns conservatively:
  duration-aware sharding may learn from pytest-xdist-style load balancing,
  shard environment contracts may follow Bazel-style `TEST_TOTAL_SHARDS` /
  `TEST_SHARD_INDEX` conventions, and changed-file routing may grow toward
  Pants-style changed-target selection with dependents. Do not add a second
  runner framework.

Current facts to preserve:

- `buildtool changed`, `changedFast`, `headless`, and `gui` remain the public
  build tasks.
- CI non-GUI shards already finish their MATLAB test steps quickly relative to
  `matlab-actions/setup-matlab`; avoid adding more default push jobs unless
  current CI evidence changes.
- GUI validation is opt-in for workflow dispatch and scheduled runs; local GUI
  sharding is already supported through `runLabKitTests` `ShardCount` and
  `ShardIndex`.
- Artifacts under `artifacts/profile/` and `artifacts/test-results/` are
  ignored evidence, not tracked fixtures.
- Feature-branch work in this route should not bump facade or app versions on
  every small commit. Before squash, PR handoff, or direct `main` integration,
  compare against latest `main` and make the required aggregate version bump
  once.

Route status:

- Timing baseline reporting is now routed through `scripts/summarize_junit.py`,
  which emits slow-test rows plus deterministic and duration-aware shard
  estimates from each JUnit report.
- Semantic app debounce and scale-bar tool debounce now register as GUI idle
  pending work for tests; fixed `pause(0.65)` waits have been removed from the
  automated GUI test tree.

Required workstreams:

1. Timing baseline:
   - add or extend a timing summary tool that reads JUnit XML and reports case
     counts, total test time, slowest cases, deterministic shard estimates, and
     duration-aware shard estimates
   - add lightweight profiling recipes for test discovery, representative GUI
     cases, and changed-plan startup
2. Fixed-wait removal:
   - expose the existing GUI idle/debounce wait helper for direct tests
   - replace fixed GUI waits such as `pause(0.65)` and layout sleeps with
     event-driven waits or bounded stability checks
   - use short test-only debounce settings only where the spec under test can
     safely override production defaults
3. Focused GUI decomposition:
   - split oversized GUI tests, starting with
     `GuiLayoutUiDeclarativeAppTest`, into focused contract tests
   - keep one lightweight integration smoke test for app-builder composition
   - avoid reintroducing launch-only duplicates for apps already covered by
     real workflow tests
4. Shard quality:
   - keep current deterministic modulo sharding as the fallback
   - add optional duration-aware sharding from recent timing artifacts when it
     proves better balance
   - support environment-variable shard inputs without changing the public
     build-task surface
5. Runner startup:
   - profile and reduce repeated path setup and suite discovery costs
   - avoid triggering launcher/app catalog discovery during runner paths that
     do not need it
6. CI strategy:
   - keep default push/PR non-GUI job count conservative while setup cost
     dominates
   - consider GUI matrix sharding only for workflow-dispatch or scheduled GUI
     runs, where wall-clock time matters more than runner-minute cost

Non-goals:

- Do not remove GUI workflow coverage just to make timing numbers smaller.
- Do not move app-specific workflow logic into `+labkit`.
- Do not add another custom runner or bypass MATLAB `matlab.unittest`.
- Do not make ordinary push CI run all GUI tests by default.
- Do not cache license, keychain, or MATLAB private runtime state.

Validation gates:

- For migration-guide-only updates, run or justify the narrow project
  guardrail scope.
- For runner, planner, or shared test-helper changes, run the focused changed
  plan first, then the narrowest affected suite if a failure localizes.
- For GUI wait or GUI test decomposition changes, run the affected GUI suite
  with hidden GUI mode and compare timing artifacts before and after.
- For CI workflow changes, inspect the triggered `MATLAB Tests` run and report
  setup time, test step time, and any skipped GUI/coverage jobs explicitly.

Completion criteria:

- The route can be retired when timing summary evidence exists, fixed GUI
  sleeps are removed or justified, oversized GUI tests are decomposed enough
  for focused reruns, shard balance is evidence-backed, and CI job structure
  reflects current setup-versus-test timing.
- When complete, shrink this section back out of the ledger and preserve only
  current contracts in source, tests, docs, or guardrails.

## Long-Term Compatibility Queue

The DTA facade intentionally keeps legacy bridge fields beside canonical
unit-explicit fields. This is compatibility debt, not current cleanup debt.

Do not remove fields such as chrono `t`, `Vf`, `Im`, `alignTime`,
`tAligned`, or EIS `Pt`, `Freq`, `Zreal`, `Zimag`, `negZimag` during ordinary
runner cleanup. A removal requires an explicit DTA major-version route after
electrochem apps and tests have moved to canonical fields.

## Migration Standard

Apps are first-class products. `+labkit` stays a small domain-neutral
foundation with UI, image, DTA, RHS, and biosignal facades. App-specific
calculations, summaries, plots, exports, workflow wording, file conventions,
and result schemas stay under the owning app tree.

A healthy runner owns orchestration only. App-owned helpers own deterministic
or explicitly side-effecting app behavior. Reusable framework helpers own
app-neutral mechanics that multiple apps share.

Migration progress means:

- a responsibility boundary becomes clearer
- deterministic behavior becomes directly testable
- the real GUI or app path uses the extracted helper
- duplicate app-neutral mechanics are removed from apps
- the total cognitive load of the workflow falls

Use large-project governance principles when judging helper organization:

- Optimize for future readers and maintainers. A new file must make the
  workflow easier to understand at the call site, not merely shorter.
- Review complexity at multiple levels: expression, function, file, package,
  and public facade. File length is a backstop; nesting, local state, coupling,
  side effects, and unclear ownership are stronger extraction signals.
- Keep private interfaces private. App-owned implementation helpers stay under
  role packages, framework-private helpers stay under facade `private/`
  folders, and test-only helpers stay under `tests/`.
- Prefer locally consistent, tool-checkable rules over personal taste. If the
  rule cannot be audited with low false-positive risk, keep it as guidance and
  a dry-run report.

Migration is not progress when it only:

- moves a large block into another large file
- turns one obvious line into a one-line helper
- hides app-specific workflow behind a generic name
- adds guardrails that are noisier than the drift they prevent
- adds docs without retiring stale debt or clarifying an active contract

## Future Debt Rules

- If guardrails detect new migration debt, update this ledger and the affected
  source or tests together.
- If debt inventory is empty, prefer shrinking this ledger over adding roadmap
  prose, scripts, or new governance layers.
- Keep completed migrations as historical baselines only when they clarify a
  current guardrail invariant.
- Treat line-count budgets as backstops, not design goals.
- Do not add a minimum-line-count guardrail. Use the helper audit's boundary
  class, call count, test references, and review reason to distinguish cosmetic
  extraction from legitimate small contracts.
- Do not split a runner or long implementation file merely to lower its line
  count. Extract only a cohesive behavior contract whose name, tests, and real
  GUI/app call path make the new file independently meaningful.
- Use `labkit-boundary-guard` before promoting behavior to `+labkit`.
- Use `labkit-test-planner` for validation routing and `docs/testing.md` for
  exact commands.
