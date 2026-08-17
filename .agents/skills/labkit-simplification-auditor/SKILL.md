---
name: labkit-simplification-auditor
description: "Use when finding, reviewing, or implementing evidence-backed LabKit simplifications involving dead, duplicated, speculative, over-built, compatibility-only, or unnecessarily hand-rolled code, tests, APIs, state, or documentation. Do not use for broad cleanup based only on style, file length, or a desire to reorganize working code."
---

# LabKit Simplification Auditor

Prefer a few proven reductions over a catalog of guesses. Read the applicable
`AGENTS.md`, current architecture, owning source and tests, public contracts,
component history, and active migration ledger before judging a candidate.

## Find candidates

Use repository search and call-site inspection to separate:

- current production consumers;
- configuration, persistence, export, launcher, callback, and dynamic entry
  paths;
- tests, docs, examples, and compatibility-only consumers;
- active migration work and historical residue.

Strong candidates include unused public or private surfaces, mirrored state,
duplicate workflow policy, tests that are the only consumer of retired
behavior, abstractions without a current owner, compatibility paths with no
supported input, and repeated agent or command work that belongs in one
deterministic owner.

Do not infer dead code from a single textual search when MATLAB dispatch,
callbacks, function handles, launcher discovery, saved-data migration, or App
definitions can reach it. Do not treat an App-specific formula or workflow as
generic duplication merely because another App has similar code.

## Prove the reduction

For each candidate, state:

1. the current owner and observable contract;
2. every production, compatibility, test, and documentation consumer;
3. what code, state, API, test, or prose disappears;
4. preserved behavior and intentionally changed behavior;
5. scientific, saved-data, public API, manual GUI, and release risks;
6. the evidence that proves the final smaller design.

Use `labkit-boundary-guard` when ownership or a public surface changes,
`labkit-scientific-change-guard` when outputs or scientific meaning can change,
and `labkit-test-planner` before selecting removal evidence. MATLAB, declared
MathWorks products, and repository code remain the production dependency set;
do not propose a third-party runtime merely because a dependency would delete
local code.

Reject or narrow a candidate when a current consumer exists, compatibility is
still supported, the proposal only relocates complexity, or removal requires a
new generic abstraction larger than the code it replaces. File size and line
budgets are signals to inspect ownership, never extraction targets.

## Implement and report

When the user asks only for an audit, report ranked candidates and evidence
without editing. When implementation is requested, remove one coherent owner
at a time, update its observable tests and documentation, and preserve rollback
and failure semantics before deleting the old path. Retire obsolete Skill or
agent guidance together with the product workflow it described.

Report candidates accepted and rejected, net surface removed, preserved and
changed contracts, validation, compatibility and manual-review boundaries, and
follow-up that remains genuinely independent.
