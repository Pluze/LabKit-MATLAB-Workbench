# Test Rules

Tests mirror source ownership and use MATLAB's official test framework.

## Structure

- Runnable tests live under `tests/cases/unit`, `contract`, or `gui`.
- App tests use explicit physical owners: `unit/apps/<family>/<app_slug>/`
  followed by `appContract`, `workbench`, or the concrete source capability.
  App GUI tests use `gui/apps/<family>/<app_slug>/smoke`, `workbench`, or a
  concrete source capability. Every public App also owns an independently
  selectable `contract/apps/<family>/<app_slug>/isolatedPath` proof; tests
  that genuinely constrain more than one App belong in `contract/apps/shared`.
- Reusable library tests use `unit/labkit_framework/<area>` and
  `gui/labkit_framework/<area>`.
- Project contracts are grouped under `contract/project/<topic>`; project GUI
  tests use `gui/project/<area>`.
- `tests/shared` contains reusable test-facing fixtures and assertions.
  `tests/runner` contains only runner selection, setup, progress, artifact, and
  validation-plan support. Delete unused helpers instead of preserving a
  speculative test API.

## Runner and routing

- `buildfile.m` owns stable human/CI tasks; `runLabKitTests.m` is the low-level
  selector. Do not add a parallel runner, per-app build tasks, or selector
  lists in workflow YAML.
- Keep public tasks compact. Improve changed-file routing before adding a task.
- Broad build tasks and CI use the same single-process runner. Do not add
  worker orchestration without a reproducible end-to-end wall-clock benefit
  large enough to justify extra CPU, licensing, platform validation, status,
  and failure-diagnosis costs.
- Progress output keeps structured artifacts plus concise current-test and ETA
  updates for humans.
- Focused iteration normally uses `runLabKitTests("Files", ...)`; use `Suites`
  for folders and `Tests` for class or method names. Run `changedFast` at a
  coherent pre-push checkpoint; CI owns the complete post-push validation.
  After a failure, repair and rerun the narrowest failed file or method.
- Unknown changed paths fall back to full non-GUI validation rather than a
  narrow false signal. App changes select only their explicit owner scopes,
  smoke proof, and isolated-path contract; do not reintroduce family-level
  test fallbacks or infer a test kind from an unprefixed selector.
- Keep every semantic route in a changed-file plan. The runner resolves those
  routes to exact test identities and executes each identity once, preserving
  route reasons without relying on folder-overlap suppression.
- Framework downstream GUI rules select a deterministic minimum smoke set from
  `RouteFeature:` test tags. A missing required feature is a visible metadata
  gap and safely selects every affected App smoke instead of narrowing.
- Exact public tasks and examples belong only in
  `docs/development/maintain-and-release/testing.md`.

## Test design

- Unit tests call behavior; source-text scans belong only in project
  guardrails.
- App-owned calculations and exports have direct tests. GUI structural tests
  prove launch/layout/callback wiring; workflow tests prove bounded synthetic
  flows. Neither substitutes for manual visual, pointer, native-dialog, or
  scientific validation.
- Prefer semantic controls, events, numeric outputs, export schemas, axes
  properties, and debug traces over component counts, fixed sleeps, or whole
  screenshots. Use bounded idle/stability helpers for asynchronous UI work.
- Tests use the app's label/choice owner instead of duplicating state literals.
- Compatibility assertions are isolated in named compatibility tests; ordinary
  tests use current schemas and APIs.
- Public `Example:` help blocks execute in a clean session. Interactive or
  file-dependent snippets remain `Typical Call:`.

## Guardrails

- Guardrails protect current public boundaries and known failure modes. Do not
  preserve completed migration routes, non-blocking audit machinery, exact
  helper inventories, or line-count-driven architecture.
- Effective MATLAB line counts exclude blank and full-comment lines. Physical
  lines are diagnostic only.
- Toolbox debt checks require an exact visible product call, owned fallback,
  fallback/idempotency/parity tests, and documented tolerance; they never hide
  dependency discovery.
- Version/history checks derive components from source and changed paths, not a
  duplicated registry.
- Repository-wide scans reuse cached file/content inventories when possible.
- Never add Code Analyzer suppression pragmas.

## Fixtures and GUI safety

- Fixtures are minimal and synthetic. Never track real lab filenames, paths,
  timestamps, subject/device identifiers, proprietary metadata, or raw local
  samples.
- Parser fixtures preserve only the structural details needed for regression.
- Hidden GUI tests create real MATLAB figures and controls. Use
  `matlab.unittest.TestCase` for hidden semantic interaction; reserve
  `matlab.uitest.TestCase` for visible driver gestures.
- Do not run manual interactive workflows in `-batch`. Broad GUI runs can steal
  focus and should be used only when required.

Update `docs/development/maintain-and-release/testing.md` when public tasks, validation strategy, CI
scope, test layout, or fixture policy changes.
