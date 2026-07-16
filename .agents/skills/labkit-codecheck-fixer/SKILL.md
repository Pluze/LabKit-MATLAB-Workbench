---
name: labkit-codecheck-fixer
description: "Manual trigger only: use when the user explicitly asks to run MATLAB Code Analyzer and fix one named file or the first reported file."
---

# LabKit Code Analyzer Fixer

Use only on explicit request. Code Analyzer reports are a maintainer tool, not
an ordinary CI or review gate.

## Read

Read `AGENTS.md`, nearest scoped rules, the target file and focused tests, and
`docs/development/tools/codecheck.md`. Use the boundary guard if ownership
would move and the test planner for validation.

## Workflow

1. Run the launcher's **Run Code Analyzer** action or call
   `runCodecheckReport(root,"OpenReport",false)`. Reports are timestamped
   `artifacts/code-check/matlab_code_issues_*.json/.html`; use the returned
   `jsonFile`, not a fixed filename.
2. Use the user-named file, or choose the first file with an unsuppressed issue
   in the newest report from this run.
3. Fix all findings for that file coherently. Preserve behavior and public
   contracts; prefer correct initialization, preallocation, placeholders, and
   clear control flow. Never add `%#ok` suppressions or conceal calls.
4. Run the smallest source-aligned tests.
5. Generate a fresh timestamped report and confirm that the target file has no
   unsuppressed issues. Repeat only for that file.

Do not stage, commit, or push unless requested. Report target, analyzer IDs,
behavior-preservation strategy, test results, both report paths, target-file
status, and other findings intentionally left out of scope. Do not claim
project-wide cleanliness unless the fresh report contains no issues.
