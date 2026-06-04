# Tests Agent Rules

Tests mirror source ownership. Do not create a parallel runner framework unless explicitly approved.

## Read Before Editing

- `docs/testing.md`
- affected source files
- nearby tests under `tests/suites/<target>/`

## Test Layout

- Add focused tests under `tests/suites/<target>/test_*.m`.
- Keep architecture guardrails in the narrowest project-suite file that matches the concern.
- Use `tests/helpers/` only for setup, lookup, assertion, cleanup, and fixture-building helpers.
- Do not move app-specific formulas, expected scientific values, result schemas, or export columns into shared test helpers.
- Boundary tests may require app-owned logic to stay under the owning app tree, but should not require GUI-free helpers to remain inside the public app entry-point file or assert exact app-private helper file lists.
- When one test file grows too broad, add new focused `test_*.m` files instead of appending unrelated coverage.
- GUI tests are structural launch/layout/callback checks; do not claim full interactive workflow validation from automated GUI tests.

## Fixture and Hygiene Rules

- Keep fixtures synthetic and minimal.
- Never copy raw local lab files, real filenames, timestamps, absolute paths, subject names, device IDs, or proprietary metadata into tracked files.
- Parser regressions should preserve only structural format details required for coverage.
- Run `scripts/run_matlab_tests.sh --suite project` after fixture, hygiene, architecture, or test-layout changes.

## Documentation Sync

- Test layout, validation strategy, CI scope, or fixture policy changes update `docs/testing.md`.
- Agent-specific validation routing or fixture-handling rule changes update this file.
- Do not update this file for ordinary test additions that follow the existing layout and policies; state that docs/AGENTS were unchanged because contracts were preserved when the change is nontrivial.
