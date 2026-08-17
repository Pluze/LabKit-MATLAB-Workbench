---
name: labkit-test-planner
description: "Use for validation planning, MATLAB test execution, CI scope, GUI checks, fixtures, or test-catalog changes. Do not use to widen validation without a source-owned contract or to perform general commit hygiene."
---

# LabKit Test Planner

Read repository rules, affected source/specification, and the testing manual.
Read catalog implementation only when changing or diagnosing catalog behavior.

## Plan from production ownership

1. Start with `labkittest.explain(SOURCE_FILE)`.
2. Add evidence with `labkittest.createSpec`; use a Regression, Invariant, or
   Compatibility reason and resolve ambiguous contracts explicitly.
3. Iterate by owner/contract or the catalog's bounded file closure.
4. Run `changedFast` once only when develop is ready for final PR review.

A missing contract or zero selection is not passing evidence. Every changed
`projectSpec.m` requires nonempty App-owned persistence evidence. When a broad
framework owner would defeat narrow iteration, report its selected count and
run already identified specification files through the bundled
`scripts/runFocusedSpecs.m`; never use it to bypass missing catalog ownership.

## Choose evidence

Prefer calculation/parser/migration, then presenter/renderer/callback/state,
then hidden-GUI structure, and finally one bounded App workflow when lower
layers cannot prove the contract. Hidden GUI does not prove native dialog,
visual quality, pointer feel, real-data suitability, or scientific validity.

Use host permission for MATLAB, hidden figures for batch GUI work, and minimal
synthetic fixtures. A long run must expose durable progress; a client timeout
is not test evidence or a MATLAB failure.

Repository profiles are headless, hidden GUI, path-isolated, coverage, and
`changedFast`. Documentation belongs to `docsCheck`; unknown changed paths fail
planning until assigned an owner or explicit ignore reason.

## Report and repair

Report exact owner/contract or profile command, selected count, result,
artifact, GUI/manual boundary, and deferred broader gates. For final integration
include `changedFast` and CI state for the exact pushed commit.

For CI failure, inspect the failed identity, reproduce its smallest method,
specification, or owner, repair that source boundary, rerun the same evidence,
and let CI restore the full claim. Do not repeat broad local gates for each
repair or invent a third CI scope.
