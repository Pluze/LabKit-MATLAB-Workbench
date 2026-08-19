---
name: labkit-boundary-guard
description: "Use for changes to +labkit, public APIs, package ownership, helper promotion, App-versus-library boundaries, or production runtime dependency decisions. Do not use for an App-local implementation that cannot affect a shared boundary or dependency."
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

## Guard the Base MATLAB boundary

For every new or changed production dependency, identify the direct callable
symbol and its owning MathWorks product before accepting the design. Production
Apps, facades, launchers, and shipped tools may use only Base MATLAB and
repository code. Do not retain an optional Toolbox call behind `exist`,
`license`, `try/catch`, acceleration, or fallback logic; replace it or report an
architecture blocker.

Use `matlab.codetools.requiredFilesAndProducts` as advisory discovery, not as
sole proof: trace every non-MATLAB product to a direct source symbol because
name collisions can produce false positives. Search the complete production
diff for that symbol and qualified package, run focused behavior without the
product, and rely on clean no-Toolbox CI for executable closure. When retiring
a concrete Toolbox gateway, add the smallest source guard that prevents its
return. Do not create a product-debt registry.

Do not infer product ownership from a `parallel.*` namespace alone. MATLAB
owns `backgroundPool`, explicit `parfeval(backgroundPool,...)`, and
`parallel.pool.PollableDataQueue`; their no-Toolbox contract is one background
worker. Parallel Computing Toolbox owns `parpool`, `parfor`, `spmd`, pool and
cluster objects, and multi-worker acceleration. Guards should reject those
specific boundaries while allowing the explicit Base MATLAB background path.

## Decide background execution

Use `labkit-performance-profiler` first and reject background execution when
foreground blocking has not been measured in the affected workflow. Do not
infer a responsiveness problem from callback length, a progress message, or a
single unmeasured run.

Accept a background boundary only when the work is one of these shapes:

- a UI-free computation that receives and returns data-shaped values without
  retaining App state, graphics, Runtime, or `CallbackContext` handles;
- a long-lived service with natural exclusive ownership of a resource, such
  as one device connection, whose client communicates through data-shaped
  commands and events.

Before accepting either shape, require explicit progress, failure,
cancellation, close cleanup, replacement and stale-result behavior. Preserve
deterministic outputs with direct parity evidence. Reject the design when the
new task lifecycle exceeds the measured responsiveness benefit, when an
existing transactional run-to-completion path already meets that benefit, or
when it is expected to isolate a hung MATLAB client. Process-isolated GUI or
diagnostics must be started by the user or environment, never by repository
production shell code.

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
select it. Report the ownership decision, rejected alternatives, deliberately
local/private behavior, validation, and manual checks.
