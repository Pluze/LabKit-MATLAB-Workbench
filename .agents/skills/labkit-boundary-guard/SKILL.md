---
name: labkit-boundary-guard
description: "Decide LabKit public API, package ownership, helper promotion, runtime dependency, and background-execution boundaries. Ordinary implementation within an unchanged private or App-local boundary does not require this workflow."
---

# LabKit Boundary Guard

Read applicable ancestor rules and affected code/tests. Read architecture and
the owning manual when their boundary is being decided. Treat `+labkit/AGENTS.md` as the authority for current
framework and facade contracts.

## Decide ownership

Before promotion into `+labkit`, require a domain-neutral contract, independent
tests, and two real consumers or a clear fit in an existing facade. Reject App
units, thresholds, wording, plots, results, exports, and workflow policy.
Duplication, helper length, and callback size are not sufficient evidence.

Apply the root ownership decision order. Keep domain facades GUI-free and
App-free; use `+labkit/AGENTS.md` for public SDK and private runtime boundaries.
A shared implementation alone does not require a new public callable API.

## Guard the Base MATLAB boundary

For every new or changed production dependency, identify the direct callable
symbol and its owner before accepting the design. Production Apps, launchers,
shipped tools, and ordinary facades may use only Base MATLAB and repository
code. A hardware facade may depend on fixed end-user-installed vendor software
only when `+labkit/AGENTS.md` names the exact private adapter as a current
production allowance. The adapter must offer a no-hardware availability check,
fail with stable facade diagnostics, never download or bundle the dependency,
return only MATLAB-native values, and be protected by an exact-file/count
source guard. Apps declare and call the facade rather than the vendor runtime.
Do not retain an optional Toolbox call behind `exist`,
`license`, `try/catch`, acceleration, or fallback logic; replace it or report an
architecture blocker.

Use `matlab.codetools.requiredFilesAndProducts` as advisory discovery, not as
sole proof: trace every non-MATLAB product to a direct source symbol because
name collisions can produce false positives. Search the complete production
diff for that symbol and qualified package, run focused behavior without the
product, and rely on clean no-Toolbox CI for executable closure. When retiring
a concrete Toolbox gateway, add the smallest source guard that prevents its
return. Do not create a product-debt registry.

For Base MATLAB background primitives, apply the root dependency contract.

## Decide background execution

For proposed background work, read [background execution](references/background.md).

When an App calls `labkit.<facade>`, require the matching facade range in its
definition and conformance coverage for declaration completeness. Runtime
launch must assert declared ranges before native window creation.

## Prove the result

For public additions, require complete help, focused tests, facade version,
owning docs, and component history. For an App SDK extension, also show repeated
App need or a framework-owned lifecycle/consistency problem and explain how the
paved road becomes simpler.

Run owner evidence, project boundary guardrails, and downstream App or GUI
evidence when the App-facing contract changes. Use `labkit-test-planner` to
select it. Report the accepted ownership, material rationale not recoverable
from the final diff, intentionally local/private behavior, validation, and
manual checks.
