---
name: labkit-simplification-auditor
description: "Use to find, review, or implement evidence-backed LabKit simplifications involving dead, duplicated, speculative, over-built, compatibility-only, or unnecessarily hand-rolled code, tests, APIs, state, or documentation. Candidates require current contract and consumer evidence."
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

Classify maintenance consumers separately from product consumers. Tests,
documentation, sample generators, developer menus, adapters, migrations, and
compatibility branches do not prove a product need when they only exercise or
explain one another. Trace the original user or runtime outcome; retire the
whole self-maintaining cluster when no supported outcome remains.

Treat uniformity as a cost that needs evidence. Do not keep a common schema,
mode, option, persistence protocol, or fixture model merely because several
owners can be made to implement it. Require the owners to share the same
current semantics and lifecycle; otherwise preserve ordinary local values and
different product-specific designs.

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
