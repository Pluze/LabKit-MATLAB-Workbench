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
an App callback file shorter are not sufficient evidence.

A shared facade may implement caller-selected preview sampling, but it retains
native pixels by default; the App owns every finite responsiveness-versus-
fidelity budget. Likewise, a read-only exact saved-data migration is a bounded
persistence contract, while simultaneous old and current fields on a live
value are competing models. Retire live aliases and their consumers together
under an explicit breaking facade range.

Use this escalation order for new behavior:

1. keep product meaning in the owning App capability;
2. extend an existing focused public contract when the option, method, or
   operation is a natural part of that contract;
3. add private framework/runtime capability when implementation must be shared
   but App authors do not need a callable contract;
4. add a new public API only for stable use by multiple Apps, or when putting
   the behavior into the nearest API would make that API an ambiguous bucket.

Do not create a narrow public helper merely because the implementation lives
in `+labkit`. Conversely, do not overload an existing API with unrelated modes
to avoid every new name; a cohesive new capability is clearer once the
multi-consumer or anti-bucket threshold is met.

Keep domain facades GUI-free and app-free. `labkit.app` is the sole App SDK.
Concrete controls, registries, queues, interaction runtimes, persistence
storage, and lifecycle handles stay private. App metadata stays in app-owned
`definition.m`; separate App `version.m` and requirements registries are
retired. `labkit.contract` validates facade ranges; it is not an App metadata
registry.

The App SDK is a stable replacement contract. `labkit.app.view.Snapshot` is
complete, layout nodes own direct callbacks and renderers, acquired render
surfaces cannot escape their event scope, and static layout compilation is
cached rather than repeated per presentation.

Public API additions require a complete MATLAB help contract, focused tests,
facade version update, owning docs, and component history. Internal refactors
that preserve the public boundary do not require a new API or governance rule.

For the App SDK, also apply the authoring extension gate: require repeated need
from at least two Apps or one framework-owned lifecycle/consistency problem.
Measure the paved-road effect. Prefer a strict binding, inferred registration,
or framework default when it removes repeated App callbacks/presenter glue;
do not make ordinary authors maintain a second handler or capability list.
Keep the public root small and partition optional capabilities by purpose:
`layout`, `view`, `event`, `interaction`, `plot`, `project`, `result`, and
`dialog`. Reject names that require reading implementation code to distinguish
their purpose.

Apply the same discoverability rule inside migrated Apps: do not forward SDK
values through untyped app-local parameters. Declare runtime-injected contexts
and event payloads by concrete type in callback `arguments` blocks.

## Validation and handoff

Run the owning framework suite, project boundary guardrails, and downstream app
or GUI tests when the app-facing contract may change. Report the ownership
decision, what deliberately stayed app-local/private, validation, and remaining
manual checks.
