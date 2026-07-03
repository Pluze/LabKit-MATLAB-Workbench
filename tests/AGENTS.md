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
- Keep reusable `+labkit` framework tests under
  `tests/cases/<kind>/labkit_framework/<area>/`.
- Keep project-level GUI entry points such as the root launcher under
  `tests/cases/gui/project/<area>/`.
- Use `TestTags` such as `Gesture`, `Workflow`, or `Structural` for test style;
  do not create extra ownership paths for style categories.
- Do not add a separate custom runner or direct pass/fail test tree. Build
  tasks are the human and CI entry points; `tests/runLabKitTests.m` is the
  lower-level implementation behind those tasks.
- Do not add public build tasks for every timing strategy. Keep the public
  build-task set compact and improve changed-file planner routing, printed
  plan reasons, representative selectors, or sharding support instead.
- CI and local broad validation should call the same public buildfile tasks.
  Workflow YAML must not call `tests/runLabKitTests.m`, maintain test-class
  selector lists, expose shard environment variables, or add the runner path by
  hand.
- Keep multi-process routing inside `buildfile.m` or the runner. If a build
  task uses worker shards, it must first probe the selected test set and then
  launch deterministic shards with distinct `RunName` values so artifact
  directories do not collide.
- Do not spawn buildfile-managed MATLAB worker processes on GitHub Actions
  unless CI licensing for independent child MATLAB processes has been proven in
  the workflow. The public CI entry should remain `buildtool headless`.
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
  versions for changed versioned code on `main`, in pull-request CI, or when
  `LABKIT_ENFORCE_VERSION_BUMPS=1` is set for final branch cleanup. Local
  feature-branch iteration may use small commits without bumping versions each
  time; before squash, PR handoff, or direct `main` push, choose the next
  version from the latest `main` version file and make the aggregate bump once.
- Boundary tests may require app-owned logic to stay under the owning app tree, but should not require GUI-free helpers to remain inside the public app entry-point file or assert exact app-private helper file lists.
- App-owned workflow packages need direct unit coverage for non-UI functions;
  GUI structural tests only prove launch/layout wiring.
- Guardrails should prevent app lifecycle orchestration from living in
  `+ui/runApp.m` or package-root eager `run.m`. Apps launch through
  `definition.m` and `labkit.ui.app.run`; workflow-first apps keep data-only
  specs in `+userInterface/buildWorkbenchSpec.m`. Ordinary tests should call
  package helpers directly.
- UI public-surface tests should assert the layered `labkit.ui.app/spec/view/tool/diag` facade and keep low-level controls, row resize, panel internals, and popout implementation private.
- GUI launch/debug tests may assert that every app supports debug launch and visible startup trace, but should not claim full interactive workflow validation.
- App GUI tests should prefer semantic contracts such as expected command
  buttons, dropdown choices, tabs, tables, axes, callbacks, workflow outcomes,
  and debug traces.
  When an app exposes user-visible labels, option values, or action text
  through an app-local `*Labels`, `*Choices`, or `*Items` helper, GUI and unit
  tests must call that helper instead of duplicating the literal strings.
  Do not use raw component-class count snapshots in app GUI tests; those couple
  app tests to framework implementation details such as whether a readonly
  display is backed by an edit field, label, or text area. Put low-level
  control-shape assertions in focused
  `tests/cases/gui/labkit_framework/...` tests only when the control shape is
  itself the framework contract.
- Do not duplicate expensive app figure launches for the same contract. If an
  app already has dedicated GUI coverage, broad entry-point checks should act
  as missing-coverage guardrails rather than launching it again. For apps
  without dedicated GUI coverage, prefer one debug launch that verifies
  startup, figure creation, path hygiene, and trace plumbing until dedicated
  layout or workflow tests are added.
- Prefer `guiTestHelpers().waitForUiIdle(...)` or a bounded state-stability
  helper over fixed GUI sleeps. If a test must wait for framework debounce,
  the owning UI/tool implementation should register pending work through the
  GUI idle appdata contract instead of relying on `pause(...)` duration.
- Scientific and visualization tests should prefer deterministic state, data,
  numeric, export, axis-label, callback-event, or debug-trace assertions over
  whole-GUI or whole-image snapshots. Use minimal synthetic inputs. Add pixel
  or screenshot baselines only when the rendered pixels are the behavior being
  protected, and keep those baselines narrowly scoped.
- Repository-wide guardrails should cache tracked-file lists or file contents
  within the test process when multiple assertions scan the same scope. Do not
  add duplicate full-tree scans that differ only by diagnostic wording.
- Project hygiene guardrails may scan app source and test text to enforce that
  declared UI label helpers own their long user-visible literals. Keep this
  check scoped to named label/choice helpers so ordinary one-off UI labels,
  axis labels, error messages, and short units do not become false-positive
  architecture debt.
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

- Use the fast changed-file build task for local iteration and the
  conservative changed-file build task for pre-handoff validation when git
  state is available. These tasks should route from the current diff and print
  why each selected scope is being run.
- If a changed-file plan fails, fix the specific failure and rerun the
  narrowest failing scope or suite directly; do not rerun the changed-file
  planner just to rediscover the same plan.
- For new timing strategies, first improve planner routing or representative
  selectors. Add a new public task only when the workflow cannot be expressed
  through the compact task set listed in `docs/testing.md` or a focused
  `runLabKitTests` invocation.
- Prefer `runLabKitTests("Suites", "...")` for rerunning a failed suite such
  as `project`, `labkit_framework/ui`, `labkit_framework/image`,
  `labkit_framework/thermal`, or
  `apps/image_measurement`. Rerun broader
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
- Thermal/FLIR parser regressions must use anonymous synthetic fixtures that
  preserve only container shape, directory records, calibration fields, byte
  order, and pixel matrix behavior needed by the test. Do not commit real
  radiometric images, camera serials, firmware strings, capture timestamps,
  source filenames, local paths, or vendor metadata copied from lab files.
  External parsers may inform compatibility analysis, but tests must exercise
  LabKit's own parser code without runtime dependency on those tools.
- Run the project guardrail task after fixture, hygiene, architecture, or
  test-layout changes. Use `docs/testing.md` for the exact command.

## Documentation Sync

- Test layout, validation strategy, CI scope, or fixture policy changes update `docs/testing.md`.
- Agent-specific validation routing or fixture-handling rule changes update this file.
- Do not update this file for ordinary test additions that follow the existing layout and policies; state that docs/AGENTS were unchanged because contracts were preserved when the change is nontrivial.
