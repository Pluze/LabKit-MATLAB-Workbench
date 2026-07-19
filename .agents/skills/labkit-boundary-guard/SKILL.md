---
name: labkit-boundary-guard
description: "Use for changes to +labkit, public APIs, package ownership, helper promotion, or app-versus-library boundary decisions."
---

# LabKit Boundary Guard

## Read

Read `AGENTS.md`, the nearest scoped rules, affected code/tests, and
`docs/development/build-apps/architecture.md`. Read only the owning
framework/library/app manual for the boundary being changed.

## Decision

Before moving code into `+labkit`, prove that it:

- has a domain-neutral name and contract;
- does not encode an app's units, thresholds, state, wording, plots, results,
  exports, or workflow order;
- is independently testable;
- is used by two real consumers or clearly belongs to an existing facade;
- makes the public API easier to understand than app-local ownership.

Otherwise keep it in the app. Duplication, helper length, and a desire to make
`stateHandlers.m` shorter are not sufficient evidence.

Keep domain facades GUI-free and app-free. `labkit.app` owns the future App
SDK; `labkit.ui` stays parser/science-free during legacy migration.
Concrete controls, registries, queues, interaction runtimes, persistence
storage, and lifecycle handles stay private. App metadata stays in app-owned
`definition.m`; separate App `version.m` and requirements registries are
retired. `labkit.contract` validates facade ranges; it is not an App metadata
registry.

For the active App SDK migration, distinguish contract approval
from release approval. Sealed immutable values and the end-to-end contract
passed Phase 1; the production API remains migration-scoped until the Phase 2
kernel gate. `labkit.app.view.Snapshot` is complete, event links use
`labkit.app.StateHandler` values, Apps declare context capabilities, acquired render surfaces cannot
escape their event scope, and static layout compilation is cached rather than
repeated per presentation.

Public API additions require a complete MATLAB help contract, focused tests,
facade version update, owning docs, and component history. Internal refactors
that preserve the public boundary do not require a new API or governance rule.

For the App SDK, also apply the authoring extension gate: require repeated need
from at least two Apps or one framework-owned lifecycle/consistency problem.
Measure the paved-road effect. Prefer a strict binding, inferred registration,
or framework default when it removes repeated App callbacks/presenter glue;
do not make ordinary authors maintain a second handler or capability list.
Keep the public root small and partition optional capabilities by purpose:
`layout`, `view`, `event`, `project`, `result`, and `dialog`. Reject names that
require reading implementation code to distinguish their purpose.

Apply the same discoverability rule inside migrated Apps: do not forward SDK
values through untyped app-local parameters. Declare runtime-injected contexts
and event payloads by concrete type in callback `arguments` blocks.

## Validation and handoff

Run the owning framework suite, project boundary guardrails, and downstream app
or GUI tests when the app-facing contract may change. Report the ownership
decision, what deliberately stayed app-local/private, validation, and remaining
manual checks.
