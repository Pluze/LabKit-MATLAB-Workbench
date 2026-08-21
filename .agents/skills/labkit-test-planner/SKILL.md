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
owner-local inputs. A fixture exists only for an automated behavior proof:
keep a single-owner builder beside its specification, share it under an
App-named `+testfixtures` package only across multiple specification owners,
and pass ordinary folders/values rather than inventing a test-only context or
pack protocol. Delete fixture-only specifications and retired manual-replay
builders. A long run must expose durable progress; a client timeout
is not test evidence or a MATLAB failure.

Repository profiles are headless, hidden GUI, path-isolated, coverage, and
`changedFast`. Documentation belongs to `docsCheck`; unknown changed paths fail
planning until assigned an owner or explicit ignore reason.

For hosted `develop` feedback, pass the complete push range's explicit changed
paths to the existing changed planner. Never infer a multi-commit push from a
clean checkout's `HEAD^..HEAD`, and never report the single-platform feedback
job as merge safety or as a replacement for local pre-PR and complete PR gates.
Let a newer push cancel superseded feedback, and inspect hosted feedback only
on user request, when checkpoint evidence needs it, or when a reported failure
blocks the current task. When an open develop-to-main PR owns complete
validation, let push-triggered feedback stop before MATLAB setup; use manual
dispatch only when independent focused evidence is explicitly needed. Do not
continuously poll non-gating development runs.

## Report and repair

Report exact owner/contract or profile command, selected count, result,
artifact, GUI/manual boundary, and deferred broader gates. For final integration
include `changedFast` and CI state for the exact pushed commit.

For CI failure, inspect the failed identity, reproduce its smallest method,
specification, or owner, repair that source boundary, rerun the same evidence,
and let CI restore the full claim. Do not repeat broad local gates for each
repair or invent a third CI scope.
