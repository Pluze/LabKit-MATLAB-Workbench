---
name: labkit-scientific-change-guard
description: "Use for changes to scientific formulas, units, ranges, defaults, selectors, tolerances, parity, or provenance in LabKit Apps and facades. Do not use for presentation-only work, documentation-only work, or a private rename that cannot change scientific outputs."
---

# LabKit Scientific Change Guard

## Establish the contract

Read `AGENTS.md`, the nearest scoped rules, the affected calculation and its
public help, the App or library manual that states the scientific meaning, and
the complete source-owned tests. Use `labkit-boundary-guard` if ownership or a
public facade may change, and `labkit-test-planner` before selecting evidence.

Write down the accepted inputs, units, defaults, valid ranges, selector labels,
formula or reference implementation, output fields and units, downstream
branches, and failure identifiers. Treat missing rationale as a question to
resolve from repository evidence or the user, not as permission to invent
science.

## Guard the change

- Reject unknown selectors and invalid numeric domains before calculation.
- Keep constants semantically named with nearby scientific rationale.
- Preserve output shapes, units, saved data, and export meaning unless the
  user explicitly changes the contract.
- When Toolbox behavior is replaced or temporarily referenced, follow the
  repository debt ledger and prove idempotency plus parity on App-consumed
  outputs within a justified tolerance.
- Prefer synthetic edge cases around valid boundaries, malformed values,
  selector alternatives, and repeated identical inputs.
- Test the calculation directly and every downstream result or presentation
  branch whose scientific meaning depends on it.

## Finish

Run the smallest scientific evidence while iterating. Update public help,
the owning manual, component version, and structured history when the
scientific or public failure contract changes. Report preserved formulas and
units, intentional numerical differences, tolerance evidence, unverified
real-data behavior, and any remaining expert-review boundary.
