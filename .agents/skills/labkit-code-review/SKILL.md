---
name: labkit-code-review
description: "Use when reviewing or auditing a LabKit change, commit, branch, or pull request for correctness, scientific meaning, ownership, compatibility, tests, documentation, and repository policy. Do not use to implement the requested change or to perform final develop-to-main PR preparation."
---

# LabKit Code Review

Review the proposed behavior, not only its diff. Establish the exact base,
head, dirty layers, and applicable `AGENTS.md` files; then read the complete
diff, affected source, source-owned tests, public help, and owning manuals.
Re-establish the boundary after a rebase, retarget, or base merge.

## Prioritize findings

Look first for defects that can change results, data, safety, lifecycle, or
supported behavior:

- scientific formulas, units, selectors, defaults, ranges, tolerance, output
  meaning, and downstream branches;
- lost compatibility, persistence, failure, status, export, or interaction
  semantics during a move or refactor;
- App policy leaking into `+labkit`, public APIs without multi-App evidence,
  or shared behavior duplicated App-locally;
- transaction, callback, resource, timer, close, rollback, and repeated-run
  behavior;
- unsanitized lab data, paths, identifiers, timestamps, or realistic fixtures;
- evidence that tests exercise a helper or mock while bypassing the real
  operation that owns the decision;
- missing public help, manual, version, or structured history required by the
  observable change.

Use `labkit-scientific-change-guard` for numerical or scientific contracts,
`labkit-boundary-guard` for ownership or public surfaces,
`labkit-test-planner` for evidence sufficiency, and
`labkit-documentation-maintainer` for authored documentation contracts.

## Judge evidence

Require the smallest test that would fail for the regression and additional
downstream or hidden-GUI evidence only when the affected contract reaches it.
Do not equate line coverage, a clean analyzer result, hidden GUI construction,
or a passing broad suite with scientific validity, native interaction quality,
or correct ownership. Confirm invalid and failure paths at the operation that
enforces the decision.

Treat current tests and history as evidence, not immutable requirements. Flag a
test that preserves retired behavior or implementation layout instead of the
current observable contract. Distinguish a blocker from optional simplification
or style; avoid findings based only on taste, file length, or a preference for
more abstraction.

## Report

Lead with actionable findings ordered by severity. Give each finding a tight
source range, the violated behavior or policy, and the concrete failure mode.
Then state open assumptions, unverified manual or scientific behavior, and the
validation inspected. If no findings remain, say so and name the residual
risks. Do not modify files, resolve review threads, push, or prepare the final
PR unless the user separately requests those actions.
