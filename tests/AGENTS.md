# Tests Agent Rules

Tests mirror source ownership. Do not create a parallel runner framework unless explicitly approved.

## Read Before Editing

- `docs/testing.md`
- affected source files
- nearby tests under `tests/cases/unit/`, `tests/cases/contract/`, or
  `tests/cases/gui/`

## Test Layout

- Add runnable tests under `tests/cases/unit/`, `tests/cases/contract/`, or
  `tests/cases/gui/` using `matlab.unittest` or `matlab.uitest` styles.
- Keep app GUI tests under
  `tests/cases/gui/apps/<family>/<app_slug>/` so local validation can target
  one affected app without running unrelated app GUIs.
- Keep LabKit-owned GUI entry points and reusable UI checks under
  `tests/cases/gui/labkit/<area>/`.
- Do not add a separate custom runner or direct pass/fail test tree. Build
  tasks are the human and CI entry points; `tests/runLabKitTests.m` is the
  lower-level implementation behind those tasks.
- CI may shard non-GUI runner selections across multiple GitHub Actions jobs
  for wall-clock speed. Keep those shards as thin calls into
  `tests/runLabKitTests.m` rather than adding granular public build tasks only
  for CI parallelism.
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
- Boundary tests may require app-owned logic to stay under the owning app tree, but should not require GUI-free helpers to remain inside the public app entry-point file or assert exact app-private helper file lists.
- App-owned packages need direct unit coverage for non-UI functions such as
  `+ops`, `+view`, `+export`, `+io`, or `+state`; GUI structural tests only
  prove launch/layout wiring.
- Guardrails should prevent app lifecycle orchestration from living in
  `+ui/runApp.m`; apps use package-root `run.m` plus data-only
  `+ui/buildSpec.m`. Ordinary tests should call package helpers directly.
- UI public-surface tests should assert the layered `labkit.ui.app/spec/view/tool/diag` facade and keep low-level controls, row resize, panel internals, and popout implementation private.
- GUI launch/debug tests may assert that every app supports debug launch and visible startup trace, but should not claim full interactive workflow validation.
- When one test file grows too broad, add new focused `test_*.m` files instead of appending unrelated coverage.
- GUI tests are launch/layout/callback checks; do not claim full interactive workflow validation from automated GUI tests.

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
