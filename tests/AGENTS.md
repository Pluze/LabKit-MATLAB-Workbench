# Tests Agent Rules

Tests mirror source ownership. Do not create a parallel runner framework unless explicitly approved.

## Read Before Editing

- `docs/testing.md`
- affected source files
- nearby tests under `tests/unit/`, `tests/integration/`, or `tests/gui/`

## Test Layout

- Add tests under `tests/unit/`, `tests/integration/`, or `tests/gui/` using
  `matlab.unittest` or `matlab.uitest` styles.
- Do not add a separate custom runner or direct pass/fail test tree; route
  coverage through `tests/runLabKitTests.m` and build tasks.
- Keep architecture guardrails in the narrowest project-suite file that matches the concern.
- Use `tests/helpers/` only for setup, lookup, assertion, cleanup, and fixture-building helpers.
- Use `tests/support/` for official-runner setup, artifact paths, structured
  trace capture, GUI fixture setup, and component snapshots.
- Do not move app-specific formulas, expected scientific values, result schemas, or export columns into shared test helpers.
- Keep compatibility bridge assertions isolated in named compatibility tests. Ordinary app and facade tests should prefer current canonical fields and direct package functions.
- Unit app tests should not read app source text to prove behavior. Keep source-string scans in project guardrails.
- Boundary tests may require app-owned logic to stay under the owning app tree, but should not require GUI-free helpers to remain inside the public app entry-point file or assert exact app-private helper file lists.
- Runner-migration tests should not rely only on GUI structural launches. When
  migration creates an app-owned package for DIC or wearable apps, add unit
  tests that call non-UI package functions such as `+ops`, `+view`, `+export`,
  `+io`, or `+state` directly.
- Guardrails should also prevent app `+ui/runApp.m` files from keeping
  same-named local helper copies once the behavior exists in the app-owned
  package. Ordinary tests should call the package helper; GUI structural tests
  only prove wiring/layout.
- UI public-surface tests should assert the layered `labkit.ui.app/spec/view/tool/diag` facade and keep low-level controls, row resize, panel internals, and popout implementation private.
- GUI smoke/debug tests may assert that every app supports debug launch and visible startup trace, but should not claim full interactive workflow validation.
- When one test file grows too broad, add new focused `test_*.m` files instead of appending unrelated coverage.
- GUI tests are structural launch/layout/callback checks; do not claim full interactive workflow validation from automated GUI tests.

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
