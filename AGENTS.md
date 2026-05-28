# Agent Instructions

This repository is a MATLAB refactor of legacy Gamry electrochemistry analysis GUIs into a package-backed workbench.

These instructions are written for Codex or any AI coding agent working in this repository.

---

## 1. Read Order

Before editing files, read these documents in order:

1. `AGENTS.md`
2. `README.md`
3. `REFACTOR_ROADMAP.md`
4. `MIGRATION_NOTES.md`
5. The specific legacy or package files involved in the requested task

For parser, data model, or validation work, also read:

- `docs/architecture.md`
- `docs/data_model.md`
- `docs/file_format_notes.md`
- `docs/validation_protocol.md`

For nonessential future enhancements, read:

- `docs/future_features.md`

---

## 2. Current Refactor Principle

The current priority is behavior-preserving refactoring.

The existing single-file GUIs are working research tools. The refactor should make the code easier to maintain without changing scientific outputs, GUI behavior, export formats, or plotting behavior unless explicitly requested.

Default rule:

```text
same results, less duplicate code, clearer boundaries
```

---

## 3. Allowed Work

Allowed work includes:

- Moving duplicated helper functions into `+gamrywb` packages.
- Creating package-backed parser, data, analysis, plotting, and export helpers.
- Updating legacy GUI files to call extracted functions when behavior is preserved.
- Adding tests for pure functions.
- Updating documentation to reflect completed work.
- Adding compatibility wrappers when needed to keep original command names runnable.

---

## 4. Forbidden Work Unless Explicitly Requested

Do not do any of the following without explicit user approval:

- Do not rewrite all GUIs in one pass.
- Do not start the unified workbench GUI before the package library is stable.
- Do not change scientific formulas, thresholds, integration rules, or result definitions.
- Do not change CSV column names or exported table structure.
- Do not change GUI layout, plot labels, markers, or visual behavior during behavior-preserving phases.
- Do not remove legacy GUIs.
- Do not convert struct models to MATLAB classes prematurely.
- Do not migrate code to Python or another language.
- Do not commit generated logs, local experiment output, `.DS_Store`, temporary exports, or unrelated files.

---

## 5. MATLAB Test Command

Use the repository test runner after executable MATLAB changes:

```bash
scripts/run_matlab_tests.sh
```

The script attempts to find MATLAB through:

1. `MATLAB_CMD` environment variable
2. `matlab` on PATH
3. macOS applications matching `/Applications/MATLAB_*.app/bin/matlab`

If MATLAB cannot be executed, report the blocker and perform static checks only. Do not claim tests passed if they were not run.

---

## 6. GUI Testing Warning

Do not run interactive GUI apps in MATLAB `-batch` mode.

The default test runner is for pure functions only, such as:

- parser functions
- utility functions
- data accessors
- pulse detection
- future analysis functions
- export table builders

Interactive GUI behavior should be checked manually or through a separate non-default smoke test.

---

## 7. Git Workflow

For each task:

1. Inspect current status before editing.
2. Make a small, logical change set.
3. Avoid mixing documentation cleanup, functional refactors, tests, and formatting-only changes in the same commit when possible.
4. Run the relevant MATLAB tests when executable code changes.
5. Review the diff for unrelated changes.
6. Commit with a concise message.
7. Do not force-push unless explicitly approved.

Preferred commit message examples:

```text
docs: reorganize refactor documentation
refactor: extract chrono parser helpers
test: add pulse detection regression tests
fix: preserve legacy GUI entrypoint behavior
```

---

## 8. Phase Discipline

Work on one roadmap phase at a time.

Do not move to the next phase until the current phase has:

- documented changes in `MIGRATION_NOTES.md`
- tests or static checks where possible
- no intentional scientific behavior change
- legacy GUI compatibility preserved

If a requested task is documentation-only, do not edit MATLAB source files.

---

## 9. Handoff Requirements

At the end of a task, report:

- changed files
- what was intentionally not changed
- test command run and result
- any blockers or unverified behavior
- next recommended step

If tests were not run, state why.
