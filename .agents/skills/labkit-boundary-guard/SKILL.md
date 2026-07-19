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
`definitionActions.m` shorter are not sufficient evidence.

Keep domain facades GUI-free and app-free. Keep `labkit.ui` parser/science-free;
its public layers are `runtime`, `layout`, `plot`, `interaction`, and `debug`.
Concrete controls, registries, queues, interaction runtimes, persistence
storage, and lifecycle handles stay private. App metadata stays in app-owned
`definition.m`; separate App `version.m` and requirements registries are
retired. `labkit.contract` validates facade ranges; it is not an App metadata
registry.

For the active UI explicit-contract migration, distinguish representation
approval from contract approval. Sealed immutable values passed Phase 1A;
production API freeze waits for the Phase 1B end-to-end and
runtime/performance gates. Presentation is a complete snapshot, command links
use Command values, Apps declare context capabilities, and acquired render
surfaces cannot escape their event scope.

Public API additions require a complete MATLAB help contract, focused tests,
facade version update, owning docs, and component history. Internal refactors
that preserve the public boundary do not require a new API or governance rule.

## Validation and handoff

Run the owning framework suite, project boundary guardrails, and downstream app
or GUI tests when the app-facing contract may change. Report the ownership
decision, what deliberately stayed app-local/private, validation, and remaining
manual checks.
