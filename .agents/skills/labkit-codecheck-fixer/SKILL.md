---
name: labkit-codecheck-fixer
description: "Manual trigger only: use when the user explicitly asks to run the manual MATLAB Code Analyzer JSON tool and fix the first reported file or a named reported file until that file has no codecheck messages. Do not use for ordinary development, tests, CI, reviews, or incidental Code Analyzer output."
---

# LabKit Codecheck Fixer

## Goal

Manually burn down MATLAB Code Analyzer findings for one file at a time without
turning Code Analyzer into a normal test, CI, or review gate.

Use this skill only when the user explicitly asks for this workflow, for
example:

```text
run codecheck and fix the first file
fix codecheck issues in +labkit/+biosignal/compareGroups.m
use the codecheck fixer skill
```

Do not trigger this skill just because `matlab_code_check.json` exists or
because unrelated work produces Code Analyzer messages.

## Required Read Order

1. `AGENTS.md`
2. nearest scoped `AGENTS.md` for the target file, if any
3. the target source file
4. focused tests for the target source area
5. `docs/testing.md` only if validation routing is not obvious

Coordinate with:

- `labkit-boundary-guard` when the target is under `+labkit` or a fix would
  move helper ownership across app/library boundaries.
- `labkit-test-planner` for choosing and reporting validation.

## Workflow

1. Run the manual Code Analyzer tool:

   ```matlab
   run('scripts/run_matlab_code_check.m')
   ```

   The ignored report is `matlab_code_check.json`.

2. Choose the target file:

   - If the user named a file, use that file.
   - Otherwise use the first entry in `matlab_code_check.json.files`.

3. Read only that file's messages from JSON. Fix all messages reported for that
   file in one coherent pass.

4. Fix logically, not mechanically:

   - Preserve scientific results, app workflow behavior, plots, exports, and
     public API contracts.
   - Prefer preallocation, clearer initialization, `~` placeholders, helper
     extraction, or small control-flow cleanup over adding suppressions.
   - Do not add `%#ok<...>` or weaken the suppression policy.
   - Do not change unrelated Code Analyzer findings in other files unless the
     same local edit naturally fixes them.

5. Run focused validation for the touched area. Pick the smallest
   source-aligned `buildtool` task from `docs/testing.md` that covers the
   behavior, adding the project guardrail task when project guardrails or
   suppression policy could be affected.

6. Rerun the Code Analyzer tool and confirm the target file no longer appears
   in `matlab_code_check.json.files`.

7. Repeat steps 3-6 only for the same target file until it is clean, or stop and
   report the blocker if a warning cannot be fixed without behavior or boundary
   risk.

## Git Handling

After the target file is clean and validation passes, stage only the files
changed for this Code Analyzer fix. Do not commit or push unless the user
explicitly asks. Leave unrelated working-tree changes untouched.

## Output Expectations

Report:

- target file
- Code Analyzer IDs fixed
- behavior-preservation strategy
- validation commands and results
- whether the target file is absent from the refreshed
  `matlab_code_check.json.files`
- staged files
- any remaining Code Analyzer findings in other files as intentionally out of
  scope

Do not claim project-wide Code Analyzer cleanliness unless the JSON report is
empty.
