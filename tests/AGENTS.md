# Tests Agent Rules

Tests mirror source ownership. Do not create a parallel runner framework unless explicitly approved.

## Read Before Editing

- `docs/testing.md`
- affected source files
- nearby tests under `tests/cases/unit/`, `tests/cases/contract/`, or
  `tests/cases/gui/`

## Test Layout

- Add runnable tests under `tests/cases/unit/`, `tests/cases/contract/apps/`,
  `tests/cases/contract/project/`, or `tests/cases/gui/` using
  `matlab.unittest` or `matlab.uitest` styles.
- Under `tests/cases/contract/project/`, group guardrails by topic such as
  `build`, `ci`, `docs`, `hygiene`, `packages`, `runtime`, or `release`
  instead of adding unrelated project guardrails to one flat folder.
- Keep app GUI tests under
  `tests/cases/gui/apps/<family>/<app_slug>/` so local validation can target
  one affected app without running unrelated app GUIs.
- Keep LabKit-owned GUI entry points and reusable UI checks under
  `tests/cases/gui/labkit/<area>/`.
- Do not add a separate custom runner or direct pass/fail test tree. Build
  tasks are the human and CI entry points; `tests/runLabKitTests.m` is the
  lower-level implementation behind those tasks.
- CI may shard non-GUI validation across multiple GitHub Actions jobs for
  wall-clock speed. Keep those shards as CI-only buildfile tasks invoked with
  `matlab-actions/run-build`; workflow YAML must not call
  `tests/runLabKitTests.m`, maintain test-class selector lists, or add the
  runner path by hand.
- Keep local multi-suite validation as serial build-task routing, not as a
  separate parallel runner.
- Keep architecture guardrails in the narrowest project-suite file that matches the concern.
- Use `tests/shared/` for small test-facing assertions, fixture builders, GUI
  probes, cleanup, and lookup helpers. Keep ordinary MATLAB helper functions
  as one-function files unless a grouped API materially improves call sites.
- Use `tests/runner/` for official-runner setup, artifact paths, structured
  trace capture, and artifact writers that keep the test runner working.
- Do not move app-specific formulas, expected scientific values, result schemas, or export columns into shared test helpers.
- Keep compatibility bridge assertions isolated in named compatibility tests. Ordinary app and facade tests should prefer current canonical fields and direct package functions.
- Unit app tests should not read app source text to prove behavior. Keep source-string scans in project guardrails.
- Version-change guardrails belong in the project contract suite and should use
  git changed paths plus current version APIs instead of maintaining app
  registries by hand. They should reject malformed, unchanged, or lower
  versions for changed versioned code.
- Boundary tests may require app-owned logic to stay under the owning app tree, but should not require GUI-free helpers to remain inside the public app entry-point file or assert exact app-private helper file lists.
- App-owned packages need direct unit coverage for non-UI functions such as
  `+ops`, `+view`, `+export`, `+io`, or `+state`; GUI structural tests only
  prove launch/layout wiring.
- Guardrails should prevent app lifecycle orchestration from living in
  `+ui/runApp.m`; apps use package-root `run.m` plus data-only
  `+ui/buildSpec.m`. Ordinary tests should call package helpers directly.
- UI public-surface tests should assert the layered `labkit.ui.app/spec/view/tool/diag` facade and keep low-level controls, row resize, panel internals, and popout implementation private.
- GUI launch/debug tests may assert that every app supports debug launch and visible startup trace, but should not claim full interactive workflow validation.
- App GUI tests should prefer semantic contracts such as expected command
  buttons, dropdown choices, tabs, tables, axes, callbacks, workflow outcomes,
  and debug traces.
  Do not use raw component-class count snapshots in app GUI tests; those couple
  app tests to framework implementation details such as whether a readonly
  display is backed by an edit field, label, or text area. Put low-level
  control-shape assertions in focused `tests/cases/gui/labkit/...` tests only
  when the control shape is itself the framework contract.
- Do not duplicate expensive app figure launches for the same contract. If an
  app already has dedicated GUI coverage, broad entry-point checks should act
  as missing-coverage guardrails rather than launching it again. For apps
  without dedicated GUI coverage, prefer one debug launch that verifies
  startup, figure creation, path hygiene, and trace plumbing until dedicated
  layout or workflow tests are added.
- Scientific and visualization tests should prefer deterministic state, data,
  numeric, export, axis-label, callback-event, or debug-trace assertions over
  whole-GUI or whole-image snapshots. Use minimal synthetic inputs. Add pixel
  or screenshot baselines only when the rendered pixels are the behavior being
  protected, and keep those baselines narrowly scoped.
- Repository-wide guardrails should cache tracked-file lists or file contents
  within the test process when multiple assertions scan the same scope. Do not
  add duplicate full-tree scans that differ only by diagnostic wording.
- Runner-complexity and helper-quality checks should start as dry-run reports.
  Do not add a blocking minimum-helper-length guardrail. If a helper-quality
  guardrail becomes necessary, it must report boundary class, call count,
  direct test references, and review reason. It must distinguish cosmetic
  micro-extraction from legitimate small public facades, framework-private
  implementation details, factories, filters, defaults, role-package contracts,
  export/dialog side-effect boundaries, and test-facing helpers. Do not use
  helper-count reduction or runner line-count reduction as proof of better
  organization unless the resulting files have coherent contracts.
- When one test file grows too broad, add new focused `test_*.m` files instead of appending unrelated coverage.
- GUI `Structural` tests are launch/layout/callback checks. GUI `Workflow`
  tests may cover hidden synthetic core flows through semantic UI operations,
  but must not claim manual visual review, scientific validity, or full
  interactive workflow validation.

## Validation Scope Discipline

- Use the changed-file planner once to choose the initial affected scope for a
  dirty worktree. If that planned run fails, fix the specific failure and
  rerun the narrowest failing scope or failing suite directly; do not rerun
  `buildtool changed` just to rediscover the same plan.
- Use the fast changed-file task for tight local iteration when shared UI or
  broad GUI-adjacent edits would trigger full downstream app GUI coverage. It
  is an iteration gate, not the final handoff gate; run the conservative changed
  task or the relevant broad task before pushing substantive
  validation-routing changes.
- Prefer `runLabKitTests("Suites", "...")` for rerunning a failed suite such
  as `project`, `labkit/ui`, `labkit/image`, or `apps/image_measurement`. Rerun broader
  build tasks only when the fix changes validation routing, touches additional
  source areas, or the user explicitly asks for a release/full gate.
- Stop an accidentally overbroad GUI run when it is not needed; GUI tests can
  steal focus and should be treated as a scarce validation resource.
- Official GUI build tasks should run with hidden test windows by default.
  Hidden mode must still create real MATLAB figures and controls rather than
  mock GUI objects; visible or minimized GUI mode is for observing the same
  automated checks during local diagnosis.

## Fixture and Hygiene Rules

- Keep fixtures synthetic and minimal.
- Never copy raw local lab files, real filenames, timestamps, absolute paths, subject names, device IDs, or proprietary metadata into tracked files.
- Parser regressions should preserve only structural format details required for coverage.
- Run the project guardrail task after fixture, hygiene, architecture, or
  test-layout changes. Use `docs/testing.md` for the exact command.

## Documentation Sync

- Test layout, validation strategy, CI scope, or fixture policy changes update `docs/testing.md`.
- Agent-specific validation routing or fixture-handling rule changes update this file.
- Do not update this file for ordinary test additions that follow the existing layout and policies; state that docs/AGENTS were unchanged because contracts were preserved when the change is nontrivial.
