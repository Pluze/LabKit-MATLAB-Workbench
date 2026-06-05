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
- Preserve public app entrypoint names and user-visible workflows.
- Keep app-specific formulas, thresholds, result schemas, exports, plot wording,
  and workflow decisions in the owning app tree.
- Do not move app-only code into `+labkit` unless it satisfies the documented
  reusable-library extraction rule.
- Production code remains function/struct based. MATLAB class-based code is
  allowed for tests that use `matlab.unittest` or `matlab.uitest`.
- Do not save raw sample paths, filenames, user names, timestamps, device IDs,
  or other sensitive sample metadata in tests, logs, artifacts, docs, or commits.
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
- Debug launch and trace are formal diagnostic surface and remain.
- `__labkit_test__` and app test handlers are legacy test compatibility surface
  and must be removed.
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
artifacts/gui/trace/
artifacts/gui/snapshots/
```

## Phase Checklist

- [ ] Phase 0: Safety baseline.
- [ ] Phase 1: New test platform skeleton.
- [ ] Phase 2: Project and style guardrails rewrite.
- [ ] Phase 3: App helper extraction before test hook removal.
- [ ] Phase 4: Delete app test backdoors.
- [ ] Phase 5: App entrypoint decomposition.
- [ ] Phase 6: Full test rewrite and old suite deletion.
- [ ] Phase 7: GUI structural and gesture coverage.
- [ ] Phase 8: CI artifact and coverage upgrade.
- [ ] Phase 9: MATLAB Project and packaging style.
- [ ] Final: delete this roadmap, prepare PR, verify CI state, merge/delete branch
  only when allowed by repo rules.

## Current Phase

Phase: 0
Status: not started
Owner notes:

- Roadmap file created on `codex/app-test-platform-rewrite`.
- No implementation phases have been executed yet.

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

Acceptance:

- Baseline facts are recorded in this file or a phase commit message.
- Any unavailable MATLAB or GUI capability is reported explicitly.

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
  setup/teardown, artifact writing, trace capture, and component snapshots.
- Update PowerShell and Bash wrappers to call the new entrypoint while preserving
  common CLI options.

Acceptance:

- New runner discovers at least a seed test.
- JUnit, HTML result, coverage, and MATLAB log output paths can be generated.
- Existing runner is still available until Phase 6.

### Phase 2: Project And Style Guardrails Rewrite

Tasks:

- Rewrite old project guardrails under `tests/integration/project/`.
- Add guardrails for:
  - public package surface
  - package dependency boundaries
  - app entrypoint boundaries
  - sensitive sample hygiene
  - absence of `__labkit_test__`, `AppTestHandlers`, and hidden load diagnostics
  - app entrypoint hard limit of 500 lines
  - public library app-facing contract comments
  - private helper implementation contract comments
  - no helper-dump packages
- Update `AGENTS.md`, scoped AGENTS files, and affected human docs when routing
  or validation contracts change.

Acceptance:

- `buildtool checkStyle` runs independently.
- Guardrails fail with clear messages that point to the owning boundary.

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

### Phase 4: Delete App Test Backdoors

Tasks:

- Remove app-local `*AppTestHandlers`, `runCompute*`, `runBuild*`,
  `__labkit_test__`, `loadFileDiagnostics`, `parse*LoadDiagnosticsRequest`, and
  `collectLoadDiagnostics`.
- Remove test-command dispatch from `labkit.ui.app.dispatchRequest`.
- Keep or rename the launch request API so it only handles normal/debug launch.
- Keep debug launch returning figure plus debug context.

Acceptance:

- Guardrails find no legacy app test command surface.
- All app entrypoints still support normal and debug launch.

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

Acceptance:

- Every public app entrypoint is below 500 lines.
- Target for major app entrypoints is near or below 350 lines.
- App behavior, export schemas, and log wording are unchanged unless explicitly
  approved by the user.

### Phase 6: Full Test Rewrite And Old Suite Deletion

Tasks:

- Rewrite old tests using official MATLAB test styles:
  - pure logic: function-based `matlab.unittest`
  - fixture/parameterized/integration: class-based `matlab.unittest.TestCase`
  - GUI: class-based `matlab.uitest.TestCase`
- Delete `tests/suites/`.
- Delete `tests/run_all_tests.m`.
- Replace old GUI helper callback-invocation style with `matlab.uitest` gestures
  where feasible.

Acceptance:

- No tracked test depends on the old custom runner.
- `buildtool test` is the full non-GUI entrypoint.

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
- Failure artifacts include trace logs, component snapshots, and callback
  ownership snapshots without sensitive sample metadata.

Acceptance:

- `buildtool testGuiStructural` is stable.
- `buildtool testGuiGesture` runs as manual/scheduled non-blocking coverage.

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
  and GUI artifacts.

Acceptance:

- CI failure can be diagnosed from uploaded artifacts without reading only the
  raw MATLAB console log.
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
| 2026-06-05 | Not run | n/a | Roadmap-only change. |

## Deviation Log

| Date | Phase | Change | Reason | Approved By |
| --- | --- | --- | --- | --- |

## Coverage Migration Map

Use this table during Phase 0 and Phase 6. Fill it before deleting old tests.

| Old test or area | New location | Status | Notes |
| --- | --- | --- | --- |
| `tests/suites/project` | `tests/integration/project` | pending | Project guardrails and style checks. |
| `tests/suites/labkit/dta` | `tests/unit/labkit/dta` | pending | Parser, facade, session, pulse behavior. |
| `tests/suites/labkit/biosignal` | `tests/unit/labkit/biosignal` | pending | Import, filtering, peaks, segments, measurements. |
| `tests/suites/labkit/ui` | `tests/unit/labkit/ui` and `tests/gui/*` | pending | Split non-GUI helpers from GUI behavior. |
| `tests/suites/apps/electrochem` | `tests/unit/apps/electrochem` and `tests/integration/app_workflows` | pending | Helper tests replace app test handlers. |
| `tests/suites/apps/dic` | `tests/unit/apps/dic` and `tests/gui/structural` | pending | Keep DIC workflow contracts app-owned. |
| `tests/suites/apps/image_measurement` | `tests/unit/apps/image_measurement` and `tests/gui/gesture` | pending | Curvature/FocusStack plus scale-bar/anchor coverage. |
| `tests/suites/apps/wearable` | `tests/unit/apps/wearable` and `tests/gui/structural` | pending | ECGPrint helper and launch coverage. |
| `tests/suites/apps/smoke` | `tests/gui/structural` | pending | All-app debug launch smoke. |

## Completion Gate

Do not delete this file until all are true:

- All phase checklist items are complete or explicitly deferred by the user.
- Final validation commands and CI status are recorded.
- No app source contains old test backdoors.
- No old custom test runner files remain.
- PR-ready branch state is clean except intentional final changes.
- The final PR plan includes this file deletion.
