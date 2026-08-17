---
name: labkit-boundary-guard
description: "Use for changes to +labkit, public APIs, package ownership, helper promotion, or app-versus-library boundary decisions. Do not use for an App-local implementation that cannot affect a shared boundary."
---

# LabKit Boundary Guard

Read the root and nearest scoped rules, affected code/tests, architecture, and
the single owning manual. Treat `+labkit/AGENTS.md` as the authority for current
framework and facade contracts.

## Decide ownership

Before promotion into `+labkit`, require a domain-neutral contract, independent
tests, and two real consumers or a clear fit in an existing facade. Reject App
units, thresholds, wording, plots, results, exports, and workflow policy.
Duplication, helper length, and callback size are not sufficient evidence.

Use this order:

1. keep product meaning in the owning App capability;
2. extend an existing focused public contract when cohesive;
3. add private shared mechanics when Apps need no callable API;
4. add a public name only for stable multi-App need or to avoid an ambiguous
   existing API.

Do not create a public helper merely because implementation is shared, or add
unrelated modes to avoid every new name. Keep domain facades GUI-free and
App-free; keep runtime and concrete UI mechanics private.

## Prove the result

For public additions, require complete help, focused tests, facade version,
owning docs, and component history. For an App SDK extension, also show repeated
App need or a framework-owned lifecycle/consistency problem and explain how the
paved road becomes simpler.

Run owner evidence, project boundary guardrails, and downstream App or GUI
evidence when the App-facing contract changes. Use `labkit-test-planner` to
select it. Report the ownership decision, rejected alternatives, deliberately
local/private behavior, validation, and manual checks.
