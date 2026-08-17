---
name: labkit-simplification-auditor
description: "Use when finding, reviewing, or implementing evidence-backed LabKit simplifications involving dead, duplicated, speculative, over-built, compatibility-only, or unnecessarily hand-rolled code, tests, APIs, state, or documentation. Do not use for broad cleanup based only on style, file length, or a desire to reorganize working code."
---

# LabKit Simplification Auditor

Prefer a few proven reductions over a catalog of guesses. Read the applicable
rules, current owner, consumers, tests, public contracts, history, and active
migration ledger.

## Find and prove candidates

Distinguish production, configuration, persistence, export, launcher, callback,
dynamic, test, documentation, and compatibility consumers. Strong candidates
include unused surfaces, mirrored state, duplicate workflow policy, tests that
alone preserve retired behavior, abstractions without a current owner, and
unsupported compatibility paths.

Do not infer dead code from one textual search when MATLAB dispatch, callbacks,
function handles, discovery, or saved-data migration can reach it. Similar App
formulas are not automatically generic duplication.

For each candidate state its owner and contract, all consumers, removed
surface, preserved and changed behavior, scientific/API/saved-data/GUI risks,
and proof for the smaller result.

Use `labkit-boundary-guard` for ownership or public surfaces,
`labkit-scientific-change-guard` for scientific meaning, and
`labkit-test-planner` for removal evidence. Reject a candidate when a current
consumer exists, compatibility remains supported, complexity only moves, or a
new abstraction exceeds the removed design.

For an audit, report ranked evidence without editing. For implementation,
remove one coherent owner at a time and preserve behavior, rollback, tests, and
documentation before deleting the old path. Retire obsolete agent guidance
with the product workflow it described.
