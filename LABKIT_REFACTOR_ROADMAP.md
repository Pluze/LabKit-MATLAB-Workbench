# LabKit App/Test Platform Rewrite Roadmap

Status: active
Branch: codex/app-test-platform-rewrite
Last updated: 2026-06-05

This file is temporary execution state for a large refactor. Read it before
starting or resuming work, update it after each completed phase or material
deviation, and delete it only after the full task is complete, CI is accounted
for, and the final PR handoff is ready.

## Operating Rules

- Work in logical phase commits on the current development branch.
- Re-read this roadmap before each phase and after each phase. Update it when
  facts change, phase scope changes, validation reveals risk, or a simpler
  implementation path becomes clear.
- Keep roadmap updates operational. Add only detail that changes execution,
  validation, risk control, or handoff; avoid turning this file into speculative
  architecture documentation.
- Preserve public app entrypoint names and user-visible workflows.
- Keep app-specific formulas, thresholds, result schemas, exports, plot wording,
  and workflow decisions in the owning app tree.
- App internals may be rewritten when that materially improves structure,
  testability, or maintainability, but the public entrypoint and default
  user-facing behavior remain stable.
- Do not move app-only code into `+labkit` unless it satisfies the documented
  reusable-library extraction rule.
- Production code remains function/struct based. MATLAB class-based code is
  allowed for tests that use `matlab.unittest` or `matlab.uitest`.
- Prefer the smallest implementation that satisfies the phase acceptance
  criteria. Do not add new public facades, generic frameworks, fixture formats,
  or CI jobs only for possible future use.
- Do not save raw sample paths, filenames, user names, timestamps, device IDs,
  or other sensitive sample metadata in tests, logs, artifacts, docs, or commits.
- Do not delete legacy tests, launch behavior, or app helper code until the
  replacement path is mapped, covered, and passing in the relevant phase.
- Before opening the final PR for the completed refactor, delete this roadmap
  unless the user explicitly asks to keep it.

## Goal

Decompose oversized app entrypoints, remove old app test backdoors, replace the
custom MATLAB test runner with the official MATLAB test framework, improve GUI
structural and gesture coverage, publish CI test/coverage artifacts, and add
project code-quality guardrails.

Final state:

- No app source contains `__labkit_test__`, `AppTestHandlers`, or hidden
  file-load diagnostics commands.
- No tracked test depends on the old self-managed pass/fail runner.
- `buildtool test` is the canonical full non-GUI test command.
- `buildtool checkStyle` enforces structure, documentation, and boundary rules.
- CI publishes JUnit, HTML test results, Cobertura coverage, HTML coverage, and
  MATLAB logs.
- GUI structural tests cover every app.
- Gesture tests cover high-risk interaction tools: runtime, anchor editor, and
  scale bar.

## Locked Decisions

- Public app entrypoint names remain stable.
- App user-facing behavior, calculation outputs, export schemas, and log wording
  stay unchanged unless a later user request explicitly approves a behavior
  change.
- Debug launch and trace are formal diagnostic surface and remain. They should
  be tightened, not removed.
- Parameterized debug launch may stay, but only for launch diagnostics options;
  it must not carry hidden file-load diagnostics, synthetic workflow commands,
  or test-only app behavior.
- `__labkit_test__` and app test handlers are legacy test compatibility surface
  and must be removed.
- Guardrails that target known legacy debt start as inventory or expected-debt
  checks, then become hard failures in the phase that removes that debt.
- The old and new test runners coexist until equivalent coverage is ported and
  recorded in the coverage migration map.
- Coverage initially reports only; do not introduce hard coverage thresholds
  until the new test architecture is stable.
- GUI gesture CI starts as manual or scheduled and non-blocking.
- MATLAB Project and packaging style are late-phase improvements, not blockers
  for app/test cleanup.

## Target Architecture

App structure:

```text
apps/<family>/<entrypoint>.m
apps/<family>/private/*.m
apps/<family>/<app_slug>/private/*.m
```

Test structure:

```text
tests/
  unit/
    labkit/
    apps/
  integration/
    project/
    app_workflows/
  gui/
    structural/
    gesture/
  fixtures/
  support/
```

Test tags:

```text
Unit
Integration
GUI
Gesture
Smoke
Surface
Style
Slow
ManualOnly
```

Artifact structure:

```text
artifacts/test-results/junit.xml
artifacts/test-results/html/
artifacts/coverage/cobertura.xml
artifacts/coverage/html/
artifacts/logs/matlab.log
artifacts/gui/trace/*.jsonl
artifacts/gui/trace/*.txt
artifacts/gui/snapshots/
```

## Diagnostic Launch And Trace Direction

Debug launch remains a supported app-facing diagnostic path:

```matlab
[fig, debug] = appName("debug", opts);
[fig, debug] = appName("--debug", opts);
[fig, debug] = appName("__labkit_debug__", opts);
```

The long-term launch contract is normal launch plus debug launch. Debug `opts`
may configure diagnostic concerns such as `enabled`, `traceEnabled`,
`logFile`, trace artifact path, visible trace mirroring, or instrumentation
level. Debug launch must not expose app-private test commands, file-load
diagnostics commands, or alternate scientific workflow paths. If the request
API is renamed during Phase 4, keep this behavior and document the replacement
as a launch/diagnostics dispatcher rather than a test-command dispatcher.

Trace should evolve from string logging into a structured diagnostic event
stream with human-readable rendering:

```text
schemaVersion, timestamp, elapsedMs, seq, runId, appName, testName,
component, event, reason, level, sessionId, details
```

Trace files should prefer JSONL for machine-readable CI and test artifacts,
with a companion text rendering for quick human inspection. The visible Log tab
may mirror trace lines only in debug mode. App user logs and diagnostic trace
events should remain linked but separable: app logs are user/workflow messages;
trace events are audit/debug records. Trace `details` must use sanitized values
and must not contain local paths, source filenames, timestamps from sample
metadata, device IDs, user names, or other sensitive sample metadata.

Allowed `reason` values:

```text
user
internal
programmatic
test
```

Reusable runtime and tool events should stop embedding component names inside
free-form strings. Prefer structured calls such as:

```matlab
trace("scaleBar", "referenceEdit.start", "user", details)
trace("runtime", "session.acquire", "internal", details)
trace("anchorEditor", "drag.commit", "user", details)
```

High-volume pointer, drag, and scroll behavior should be traced through
runtime/tool lifecycle events such as start, update, commit, cancel, restore,
and error. Default figure instrumentation should continue to skip raw
pointer/drag/scroll callbacks so debug mode remains usable.

## Safety And Scope Guardrails

Use these controls to keep the large refactor reversible and focused.

### Dynamic Roadmap Review

At the end of each phase:

- update `Current Phase`, `Validation Log`, and `Deviation Log`;
- update the coverage migration map when tests are mapped, ported, dual-running,
  deleted, or deferred;
- review whether the next phase should be narrowed, split, or reordered based on
  validation evidence;
- remove or defer speculative tasks that do not directly reduce current risk,
  simplify app structure, improve coverage, or improve CI diagnosability.

Do not add broad new abstractions just because several future phases might use
them. Add the narrow contract needed now, then generalize only after two or more
real call sites prove the shape.

### Deletion Safety

Before deleting old tests, runner files, app test handlers, or debug/request
paths:

- prove the replacement exists and is exercised by automated tests;
- record the old-to-new coverage mapping;
- run the old and new path together when feasible;
- keep a small focused diff for each deletion phase so failures can be traced
  back to one boundary.

### Guardrail Rollout

New style and architecture guardrails may be introduced in three modes:

```text
inventory     reports current state and debt counts
expected-debt fails only for new regressions outside the known debt list
hard-fail     fails for any violation
```

Phase 2 should prefer `inventory` or `expected-debt` for legacy test backdoors,
oversized app entrypoints, and old runner dependencies. Phase 4 and Phase 6
promote the relevant checks to `hard-fail` after the corresponding legacy
surface is removed.

### App Rewrite Boundary

App entrypoint internals may be rewritten during decomposition when this makes
state ownership, callbacks, or tests clearer. The stable contract is:

- public app command names remain;
- normal launch and debug launch remain;
- scientific calculations, result schemas, export formats, and default log
  wording remain stable unless explicitly approved;
- app-private helpers may be reorganized freely inside the owning app family;
- reusable `+labkit` APIs only grow when they satisfy the extraction rule.

### Risk Register

| Risk | Mitigation |
| --- | --- |
| New guardrails fail before legacy debt is removed. | Start as inventory/expected-debt; promote to hard-fail only in the removal phase. |
| Old tests are deleted before equivalent coverage exists. | Require coverage map status to reach `ported` or `dual-running` before deletion. |
| GUI gesture tests become flaky or block PRs. | Keep gesture CI manual/scheduled and non-blocking until stable. |
| App rewrites change scientific behavior accidentally. | Preserve fixtures, export schema assertions, and focused helper tests before large entrypoint changes. |
| Trace artifacts leak local or sample metadata. | Sanitize trace details and artifact writers; keep sensitive-sample guardrails active. |
| The roadmap grows into speculative architecture work. | Add only execution-relevant details and defer unproven abstractions. |

## Phase Checklist

- [x] Phase 0: Safety baseline.
- [x] Phase 1: New test platform skeleton.
- [x] Phase 2: Project and style guardrails rewrite.
- [x] Phase 3: App helper extraction before test hook removal.
- [x] Phase 4: Delete app test backdoors.
- [ ] Phase 5: App entrypoint decomposition.
- [ ] Phase 6: Full test rewrite and old suite deletion.
- [ ] Phase 7: GUI structural and gesture coverage.
- [ ] Phase 8: CI artifact and coverage upgrade.
- [ ] Phase 9: MATLAB Project and packaging style.
- [ ] Final: delete this roadmap, prepare PR, verify CI state, merge/delete branch
  only when allowed by repo rules.

## Current Phase

Phase: 5
Status: in progress
Owner notes:

- Phase 4 completed on `codex/app-test-platform-rewrite`.
- `labkit.ui.app.dispatchRequest` now handles debug launch requests only.
  Non-debug string inputs are rejected by public app entrypoints.
- Electrochem, Curvature, and FocusStack legacy bridge tests now call
  app-owned workflow helpers directly instead of sending commands through app
  entrypoints.
- App-local test handler blocks and the CSC hidden file-load diagnostics path
  were removed. DIC and ECGPrint already had no app test handler surface.
- Guardrails are promoted to hard-fail for legacy app test command references,
  app test handler functions, and hidden load diagnostics; the current
  inventory is 0/0/0.
- Current remaining expected-debt inventories are 10 app entrypoints over 500
  MATLAB-counted lines and 73 private-helper files missing top-of-file
  implementation contracts.
- Next phase decomposes app entrypoints while preserving calculation results,
  export schemas, plot/log wording, debug launch behavior, and app ownership
  boundaries.
- Phase 5 image-measurement checkpoint: Curvature and FocusStack public
  entrypoints now contain only one public function each and are below the
  500-line hard-fail target (`499` and `450` MATLAB-counted lines). Extracted
  helpers stay app-owned under the existing image-measurement app trees.

## Phase 0 Baseline

App entrypoint line counts:

| App entrypoint | Lines | Phase 5 status |
| --- | ---: | --- |
| `apps/electrochem/labkit_CIC_app.m` | 1383 | oversized |
| `apps/dic/labkit_DICPreprocess_app.m` | 1225 | oversized |
| `apps/electrochem/labkit_VTResistance_app.m` | 1049 | oversized |
| `apps/electrochem/labkit_CSC_app.m` | 963 | oversized |
| `apps/image_measurement/curvature/labkit_CurvatureMeasurement_app.m` | 825 | oversized |
| `apps/wearable/labkit_ECGPrint_app.m` | 786 | oversized |
| `apps/image_measurement/focus_stack/labkit_FocusStack_app.m` | 682 | oversized |
| `apps/dic/labkit_DICPostprocess_app.m` | 585 | oversized |
| `apps/electrochem/labkit_ChronoOverlay_app.m` | 556 | oversized |
| `apps/electrochem/labkit_EIS_app.m` | 546 | oversized |

Test suite distribution:

| Suite | `test_*.m` files | Current role |
| --- | ---: | --- |
| `tests/suites/project` | 6 | non-GUI default |
| `tests/suites/labkit/dta` | 8 | non-GUI default |
| `tests/suites/labkit/biosignal` | 5 | non-GUI default |
| `tests/suites/labkit/ui` | 11 | split non-GUI/GUI by file |
| `tests/suites/apps/electrochem` | 8 | split non-GUI/GUI by file |
| `tests/suites/apps/dic` | 1 | GUI |
| `tests/suites/apps/image_measurement` | 3 | split non-GUI/GUI by file |
| `tests/suites/apps/wearable` | 1 | GUI |
| `tests/suites/apps/smoke` | 1 | GUI |
| Total | 44 | old runner discovery |

Current CI shape:

- `.github/workflows/matlab-tests.yml` has one `pure-matlab-tests` job.
- It runs on push, pull request, and manual dispatch for `main`.
- It uses `matlab-actions/setup-matlab@v3` with R2025a and
  `matlab-actions/run-command@v3`.
- The MATLAB command is
  `addpath(fullfile(pwd,'tests')); run_all_tests(false);`.
- No JUnit, coverage, HTML, MATLAB log, or GUI trace artifacts are uploaded yet.

Current public `+labkit` surface:

| Facade | Public functions |
| --- | ---: |
| `labkit.biosignal` | 11 |
| `labkit.dta` | 16 |
| `labkit.ui.app` | 4 |
| `labkit.ui.diag` | 1 |
| `labkit.ui.tool` | 4 |
| `labkit.ui.view` | 7 |
| Total | 43 |

Legacy debt inventory:

| Debt area | Current count | Notes |
| --- | ---: | --- |
| `__labkit_test__` file matches | 0 | Phase 4 removed app entrypoint command routing and switched bridge tests to workflow helpers. |
| App test handler functions | 0 | Phase 4 removed CIC, VT, CSC, EIS, ChronoOverlay, Curvature, and FocusStack handler blocks. |
| Hidden load diagnostics matches | 0 files | Phase 4 removed the CSC file-load diagnostic path and its GUI layout test dependency. |
| App entrypoints over 500 MATLAB-counted lines | 10 of 10 | Phase 5 migration target; Phase 2 corrected the baseline to use MATLAB `readlines` counts. |
| Old runner dependency files | 8 | `tests/run_all_tests.m`, wrappers, CI, and current docs/agent routing. |

## Phase Details

### Phase 0: Safety Baseline

Tasks:

- Record current app entrypoint line counts, test counts, suite distribution, CI
  workflow shape, and public package surface.
- Run current baseline checks before changing behavior:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite project`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1`
  - GUI available: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite gui`
- Map each old test file to its future test intent so coverage is not lost when
  `tests/suites/` is deleted.
- Record current legacy-debt counts for `__labkit_test__`, app test handlers,
  hidden diagnostics commands, oversized app entrypoints, and old runner
  dependencies.

Acceptance:

- Baseline facts are recorded in this file or a phase commit message.
- Any unavailable MATLAB or GUI capability is reported explicitly.
- Coverage migration map has at least `mapped` or `deferred` status for every
  old test area before Phase 6 work begins.

### Phase 1: New Test Platform Skeleton

Tasks:

- Add `buildfile.m` with tasks:
  - `checkStyle`
  - `test`
  - `testUnit`
  - `testIntegration`
  - `testGuiStructural`
  - `testGuiGesture`
  - `coverage`
- Add `tests/runLabKitTests.m` using MATLAB official discovery, tag filtering,
  and plugins rather than a custom pass/fail loop.
- Add `tests/support/` helpers for repo root setup, fixture paths, GUI
  setup/teardown, artifact writing, structured trace capture, text trace
  rendering, and component snapshots.
- Add a structured diagnostic trace helper that records event structs with
  schema version, `runId`, optional `testName`, monotonic `seq`, elapsed time,
  reason validation, optional `sessionId`, sanitized `details`, and
  machine-readable JSONL artifact output.
- Update PowerShell and Bash wrappers to call the new entrypoint while preserving
  common CLI options.

Acceptance:

- New runner discovers at least a seed test.
- JUnit, HTML result, coverage, and MATLAB log output paths can be generated.
- Trace JSONL and text artifact paths can be generated without sensitive sample
  metadata.
- Existing runner is still available until Phase 6.

### Phase 2: Project And Style Guardrails Rewrite

Tasks:

- Rewrite old project guardrails under `tests/integration/project/`.
- Add guardrails for:
  - public package surface
  - package dependency boundaries
  - app entrypoint boundaries
  - sensitive sample hygiene
  - inventory or expected-debt checks for `__labkit_test__`, `AppTestHandlers`,
    and hidden load diagnostics until Phase 4 promotes them to hard-fail
  - inventory or expected-debt checks for app entrypoint size until Phase 5
    promotes the 500-line limit to hard-fail
  - public library app-facing contract comments
  - private helper implementation contract comments
  - no helper-dump packages
- Update `AGENTS.md`, scoped AGENTS files, and affected human docs when routing
  or validation contracts change.

Acceptance:

- `buildtool checkStyle` runs independently.
- Guardrails fail with clear messages that point to the owning boundary.
- Legacy debt guardrails clearly distinguish inventory, expected-debt, and
  hard-fail modes.

### Phase 3: App Helper Extraction Before Test Hook Removal

Tasks:

- Extract pure app-owned helpers currently exposed through app test handlers:
  - CIC: computation, voltage transient metrics, injected charge, table/export
    helpers.
  - VT: resistance computation and table/export helpers.
  - CSC: CSC computation, formatting, and plot-data helpers.
  - EIS: axis values and export helpers.
  - ChronoOverlay: pulse-gap alignment and export helpers.
  - Curvature and FocusStack: complete private helper contracts and direct tests.
  - DIC and ECGPrint: extract GUI-free calculation/export/format helpers where
    it reduces app entrypoint size.
- Place helpers under `apps/<family>/private/` only when shared by multiple apps;
  otherwise prefer `apps/<family>/<app_slug>/private/`.

Acceptance:

- Every old `__labkit_test__` command has equivalent direct helper-level test
  coverage.
- No extracted helper crosses app/library ownership boundaries.
- Replacement helper tests are passing before the corresponding app test handler
  is removed in Phase 4.

### Phase 4: Delete App Test Backdoors

Tasks:

- Remove app-local `*AppTestHandlers`, `runCompute*`, `runBuild*`,
  `__labkit_test__`, `loadFileDiagnostics`, `parse*LoadDiagnosticsRequest`, and
  `collectLoadDiagnostics`.
- Remove test-command dispatch from `labkit.ui.app.dispatchRequest`.
- Keep or rename the launch request API so it only handles normal/debug launch
  and diagnostic options.
- Keep debug launch returning figure plus debug context.
- Keep parameterized debug launch for diagnostics, but reject or ignore
  app-private test command shapes after the replacement API is introduced.

Acceptance:

- Guardrails find no legacy app test command surface.
- All app entrypoints still support normal and debug launch.
- Debug launch supports diagnostic options without exposing hidden workflow or
  file-load test behavior.
- Legacy test-backdoor guardrails are promoted to hard-fail.

### Phase 5: App Entrypoint Decomposition

Tasks:

- Decompose apps in this order:
  1. Curvature and FocusStack.
  2. DICPreprocess and DICPostprocess.
  3. CIC, VTResistance, and CSC.
  4. EIS and ChronoOverlay.
  5. ECGPrint.
- Keep entrypoint files focused on launch, GUI state, callback order, alerts,
  logging, and orchestration.
- Keep pure calculation, export, formatting, deterministic transforms, and
  plot-data preparation in app-owned private helpers.
- Internal app rewrites are allowed when they simplify state ownership or test
  seams, but each app migration should keep a focused behavior-preservation
  checklist for calculations, export schema, log wording, and default workflow.

Acceptance:

- Every public app entrypoint is below 500 lines.
- Target for major app entrypoints is near or below 350 lines.
- App behavior, export schemas, and log wording are unchanged unless explicitly
  approved by the user.
- App entrypoint size guardrail is promoted to hard-fail after the final app in
  this phase is migrated.

### Phase 6: Full Test Rewrite And Old Suite Deletion

Tasks:

- Rewrite old tests using official MATLAB test styles:
  - pure logic: function-based `matlab.unittest`
  - fixture/parameterized/integration: class-based `matlab.unittest.TestCase`
  - GUI: class-based `matlab.uitest.TestCase`
- Port old tests by coverage area and record status transitions in the coverage
  migration map.
- Delete `tests/suites/` only after all old test areas are `ported`,
  `dual-running`, or explicitly `deferred` by the user.
- Delete `tests/run_all_tests.m` only after wrappers and CI no longer depend on
  it.
- Replace old GUI helper callback-invocation style with `matlab.uitest` gestures
  where feasible.

Acceptance:

- No tracked test depends on the old custom runner.
- `buildtool test` is the full non-GUI entrypoint.
- Old runner dependency guardrails are promoted to hard-fail.

### Phase 7: GUI Structural And Gesture Coverage

Tasks:

- Structural GUI tests cover every app normal launch and debug launch.
- Structural tests validate tabs, panels, buttons, axes, result tables, logs, and
  visible debug trace.
- Gesture tests cover:
  - scale bar repeated enable/disable
  - scale bar same-value no-op behavior
  - scale bar internal sync suppression
  - scale bar reference measurement and placement lifecycle
  - anchor editor add/drag/delete/undo
  - runtime exclusive session behavior
  - pointer/drag/scroll callback restore after normal close and error
- Gesture tests assert structured trace events for scale bar, anchor editor, and
  runtime ownership transitions instead of parsing only visible text.
- Failure artifacts include structured trace JSONL, readable trace logs,
  component snapshots, and callback ownership snapshots without sensitive sample
  metadata.

Acceptance:

- `buildtool testGuiStructural` is stable.
- `buildtool testGuiGesture` runs as manual/scheduled non-blocking coverage.
- Trace event assertions can identify repeated callback loops, same-value
  no-op suppression, runtime session acquisition/release, and callback restore
  failures.

### Phase 8: CI Artifact And Coverage Upgrade

Tasks:

- Replace `matlab-actions/run-command` custom runner invocation with
  `matlab-actions/run-tests` or `matlab-actions/run-build`.
- Add PR jobs:
  - `quality`: `buildtool checkStyle`
  - `unit`: `buildtool testUnit coverage`
  - `integration`: `buildtool testIntegration`
- Add manual/scheduled jobs:
  - `gui-structural`
  - `gui-gesture`
- Upload JUnit, HTML test results, Cobertura coverage, HTML coverage, MATLAB log,
  readable trace text, structured trace JSONL, and GUI artifacts.

Acceptance:

- CI failure can be diagnosed from uploaded artifacts without reading only the
  raw MATLAB console log.
- GUI failures expose structured trace and readable trace artifacts.
- GUI gesture remains non-blocking initially.

### Phase 9: MATLAB Project And Packaging Style

Tasks:

- Add MATLAB Project file for stable path/dependency setup.
- Add `packageDryRun` and `checkProject` build tasks.
- Do not require `.mltbx` publication in this refactor.
- Update README only with stable user-facing build/test entrypoints.

Acceptance:

- `buildtool packageDryRun` verifies packaging boundaries without changing app
  usage.

## Validation Log

| Date | Command | Result | Notes |
| --- | --- | --- | --- |
| 2026-06-05 | `git diff --check -- LABKIT_REFACTOR_ROADMAP.md` | pass | Roadmap-only changes; added debug/trace modernization plus safety and scope guardrails. |
| 2026-06-05 | Phase 0 inventory | pass | Recorded app entrypoint line counts, 44 old-suite test files, current CI shape, 43 public `+labkit` functions, and legacy debt counts. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite project` | pass | MATLAB R2025b; 6 project guardrail tests passed in 1.56s. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1` | pass | MATLAB R2025b; default non-GUI suite passed in 64.42s. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite gui` | pass | MATLAB R2025b; existing GUI suite passed in 250.49s. |
| 2026-06-05 | `matlab -batch "... runLabKitTests('IncludeLegacy', false, 'RunName', 'phase1-seed')"` | pass | Official runner discovered 2 seed tests and generated JUnit plus HTML result artifacts. |
| 2026-06-05 | `matlab -batch "... buildtool testUnit"` | pass | Official unit task discovered and passed 2 seed tests. |
| 2026-06-05 | `matlab -batch "... buildtool coverage"` | pass | Generated `artifacts/coverage/cobertura.xml` and HTML coverage report for official tests. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite project` | pass | Wrapper bridge ran 2 official seed tests plus 6 legacy project guardrails. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1` | pass | Wrapper bridge ran 2 official seed tests plus legacy default non-GUI suite. |
| 2026-06-05 | `matlab -batch "... buildtool checkStyle"` | pass | Ran official style-tag seed tests plus legacy project guardrails. |
| 2026-06-05 | `matlab -batch "... buildtool test"` | pass | Ran official seed tests plus legacy default non-GUI suite. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite gui` | pass | Wrapper bridge ran existing legacy GUI suite; official GUI test count is 0 until Phase 7. |
| 2026-06-05 | `matlab -batch "... buildtool testGuiGesture"` | pass | Task is valid and currently selects 0 official gesture tests. |
| 2026-06-05 | `bash -n scripts/run_matlab_tests.sh` | blocked | Local Bash/WSL launch failed with access denied before syntax execution; PowerShell wrapper was validated. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite project` | pass | Post-doc/AGENTS/roadmap update guardrail passed with official seed plus legacy project suite. |
| 2026-06-05 | `matlab -batch "... buildtool checkStyle"` | pass | Official project/style guardrails passed; legacy project suite also passed. |
| 2026-06-05 | `matlab -batch "... buildtool testIntegration"` | pass | Official project integration guardrails passed. |
| 2026-06-05 | `matlab -batch "... buildtool test"` | pass | Official seed/project guardrails plus legacy default non-GUI suite passed. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite apps/electrochem` | pass | Electrochem helper/export tests passed after routing handlers through private workflow helpers. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite apps/electrochem --gui` | pass | Electrochem GUI/layout suite passed after callback routing changes. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite apps/image_measurement --gui` | pass | Curvature/FocusStack helper and GUI coverage passed after private helper contract comments. |
| 2026-06-05 | `matlab -batch "... buildtool checkStyle"` | pass | Expected-debt inventories after Phase 3: 14 `__labkit_test__` files, 7 handler files, 2 diagnostics files, 10 oversized app entrypoints, 73 private helper contract debt files. |
| 2026-06-05 | `matlab -batch "... buildtool test"` | pass | Broad non-GUI suite passed after Phase 3 helper extraction. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite apps/electrochem` | pass | Electrochem bridge tests passed after switching from app-entrypoint command backdoors to `electrochemWorkflow`. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite apps/image_measurement` | pass | Curvature and FocusStack bridge tests passed through app-owned workflow helpers. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite labkit/ui` | pass | Debug-only `labkit.ui.app.dispatchRequest` contract passed legacy UI helper tests. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite project` | pass | Official guardrails reported 0 legacy test-command files, 0 handler files, and 0 diagnostics files. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite apps/electrochem --gui` | pass | Electrochem GUI/layout suite passed after app handler removal and CSC diagnostics removal. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite apps/image_measurement --gui` | pass | Curvature and FocusStack GUI/layout suite passed after debug-only dispatch and FocusStack helper extraction. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite labkit/ui --gui` | pass | UI GUI/debug instrumentation suite passed after dispatchRequest contract change. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite apps/smoke --gui` | pass | All app normal/debug launch smoke tests passed after debug-only dispatch. |
| 2026-06-05 | `matlab -batch "... buildtool checkStyle"` | pass | Official hard-fail guardrails passed: 0 legacy backdoor files; 10 oversized app entrypoints; 73 private-helper contract debt files. |
| 2026-06-05 | `matlab -batch "... buildtool test"` | pass | Broad non-GUI suite passed after Phase 4 app backdoor removal. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite apps/image_measurement` | pass | Curvature and FocusStack helper/export tests passed after Phase 5 entrypoint decomposition. |
| 2026-06-05 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 --suite apps/image_measurement --gui` | pass | Curvature and FocusStack GUI/layout/debug checks passed with entrypoints at 499 and 450 MATLAB-counted lines. |

## Deviation Log

| Date | Phase | Change | Reason | Approved By |
| --- | --- | --- | --- | --- |
| 2026-06-05 | 2 | Corrected app entrypoint size baseline from PowerShell `Measure-Object -Line` counts to MATLAB `readlines` counts. | Phase 2 guardrails run in MATLAB and include blank lines; the enforceable baseline should match the enforcing tool. | Codex |
| 2026-06-05 | 3 | Used app-private `*Workflow.m` dispatch helpers for electrochem command groups instead of adding public helper packages or many one-off public facades. | MATLAB private visibility prevents external tests from directly calling app-private helpers, and grouped app-owned private helpers keep science/export logic out of `+labkit`. | Codex |
| 2026-06-05 | 4 | Added app-owned workflow wrapper functions for tests to reach GUI-free app helpers after app-entrypoint backdoors were removed. | MATLAB private helpers are not directly callable from the test tree, and wrapper functions preserve coverage without exposing hidden commands through public app launchers or moving app-specific logic into `+labkit`. | Codex |

## Coverage Migration Map

Use this table during Phase 0 and Phase 6. Fill it before deleting old tests.
Allowed status values:

```text
pending
mapped
ported
dual-running
old-deleted
deferred
```

| Old test or area | New location | Status | Notes |
| --- | --- | --- | --- |
| `tests/suites/project` | `tests/integration/project` | dual-running | 6 legacy files plus official project/style guardrails under `tests/integration/project`. |
| `tests/suites/labkit/dta` | `tests/unit/labkit/dta` | mapped | 8 files; parser, facade, session, pulse behavior. |
| `tests/suites/labkit/biosignal` | `tests/unit/labkit/biosignal` | mapped | 5 files; import, filtering, peaks, segments, measurements. |
| `tests/suites/labkit/ui` | `tests/unit/labkit/ui` and `tests/gui/*` | mapped | 11 files; split non-GUI helpers from GUI behavior. |
| `tests/suites/apps/electrochem` | `tests/unit/apps/electrochem` and `tests/integration/app_workflows` | mapped | 8 files; legacy bridge tests now call `electrochemWorkflow`; official port remains Phase 6. |
| `tests/suites/apps/dic` | `tests/unit/apps/dic` and `tests/gui/structural` | mapped | 1 file; keep DIC workflow contracts app-owned. |
| `tests/suites/apps/image_measurement` | `tests/unit/apps/image_measurement` and `tests/gui/gesture` | mapped | 3 files; legacy bridge tests now call Curvature/FocusStack workflow helpers; official port remains Phase 6. |
| `tests/suites/apps/wearable` | `tests/unit/apps/wearable` and `tests/gui/structural` | mapped | 1 file; ECGPrint helper and launch coverage. |
| `tests/suites/apps/smoke` | `tests/gui/structural` | mapped | 1 file; all-app debug launch smoke. |

## Completion Gate

Do not delete this file until all are true:

- All phase checklist items are complete or explicitly deferred by the user.
- Final validation commands and CI status are recorded.
- No app source contains old test backdoors.
- No old custom test runner files remain.
- PR-ready branch state is clean except intentional final changes.
- The final PR plan includes this file deletion.
