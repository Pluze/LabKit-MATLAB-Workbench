---
name: labkit-test-planner
description: "Use for validation planning, MATLAB test execution, CI scope, GUI checks, fixtures, or test-catalog changes. Evidence scope follows source-owned contracts; general commit hygiene belongs to labkit-checkpoint-guard."
---

# LabKit Test Planner

Read repository rules, affected source/specification, and the testing manual.
Read catalog implementation only when changing or diagnosing catalog behavior.

## Plan from production ownership

1. Start with `labkittest.explain(SOURCE_FILE)`.
2. Add evidence with `labkittest.createSpec`; use a Regression, Invariant, or
   Compatibility reason and resolve ambiguous contracts explicitly.
3. Iterate by owner/contract or the catalog's bounded file closure.
4. Run `changedFast` once only when the task branch is ready for final PR review.

A missing contract or zero selection is not passing evidence. Every changed
`projectSpec.m` requires nonempty App-owned persistence evidence. When a broad
framework owner would defeat narrow iteration, report its selected count and
run already identified specification files through the bundled
`scripts/runFocusedSpecs.m`; never use it to bypass missing catalog ownership.

## Choose evidence

Use calculation/parser/migration, presenter/renderer/callback/state, generic
hidden-GUI structure, and App workflow as distinct evidence semantics rather
than substitutes ordered only by cost. Every App requires at least one bounded
native core journey from its production source boundary to a useful result,
continuation, or supported failure. Add further journeys only for distinct
user goals, reachable state-dependent chains, or failure/recovery boundaries.
Hidden GUI does not prove native dialog, visual quality, pointer feel,
real-data suitability, or scientific validity.

Audit a changed App with `labkittest.appEvidence`. Every custom declared signal
requires an exact native-runtime operation; callback-name matching cannot
satisfy the GUI inventory. Require an owning
assertion over domain state, presentation, artifact, or supported failure.
Treat the report as an omission detector: a matched call or absence of an
exception is not passing evidence. Do not generate a control
Cartesian product; partition equivalent values and combinations by scientific
meaning, reachable workflow state, failure risk, and platform sensitivity.

For every new or materially changed test, identify the independent oracle and
one plausible production counterfactual that should make it fail for the
intended reason. Reject fixture/consumer tautologies, implementation-shaped
counts, and assertions added only to increase coverage. Use mutation testing
or a deliberate temporary mutation when proportionate, but evaluate assertion
sensitivity rather than optimizing a mutation score.

Apply the output-assertion boundary in `tests/AGENTS.md`. During failure
diagnosis, preserve the captured transcript, identify the producer-owned value
or record, and rerun the smallest evidence after moving the assertion to that
semantic boundary. Do not assign an extra line to a runtime, platform, or
framework until the retained diagnostic supports that cause.

Use host permission for MATLAB, hidden figures for batch GUI work, and minimal
owner-local inputs. A fixture exists only for an automated behavior proof:
keep a single-owner builder beside its specification, share it under an
App-named `+testfixtures` package only across multiple specification owners,
and pass ordinary folders/values rather than inventing a test-only context or
pack protocol. Delete fixture-only specifications and retired manual-replay
builders. A long run must expose durable progress; a client timeout
is not test evidence or a MATLAB failure.

Repository profiles are headless, hidden GUI, App journeys, path-isolated,
coverage, and `changedFast`. Coverage records headless logic and native journey
execution separately; report per-App and changed-line gaps without blending
them into a completeness claim. Documentation belongs to `docsCheck`; unknown
changed paths fail planning until assigned an owner or explicit ignore reason.

For hosted task-branch feedback, pass the complete push range's explicit changed
paths to the existing changed planner. Never infer a multi-commit push from a
clean checkout's `HEAD^..HEAD`, and never report the single-platform feedback
job as merge safety or as a replacement for local pre-PR and complete PR gates.
Let a newer push cancel superseded feedback, and inspect hosted feedback only
on user request, when checkpoint evidence needs it, or when a reported failure
blocks the current task. When an open PR from that task branch to `main` owns
complete validation, let push-triggered feedback stop before MATLAB setup; use manual
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
