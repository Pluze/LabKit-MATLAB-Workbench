# Migration Debt Ledger

This file records only active architecture migration or compatibility-retirement
debt. Current supported behavior belongs in `docs/`; execution rules belong in
the nearest `AGENTS.md`; completed work belongs in component history.

## Active debt

Last audited: 2026-08-24.

### Figure Studio semantic editor migration

- Owner: `apps/labkit_core/figure_studio`.
- Current problem: Figure Studio preserves a useful native axes copy and a
  portable graphics snapshot, but its editable state is still a flat style and
  canvas form. It cannot represent LabKit plot roles, object groups, inherited
  category styles, per-object overrides, complete tick text, multi-panel
  layout, compound annotations, or command history as deterministic document
  state.
- Observable effect: users cannot reliably edit the complete presentation of
  current LabKit App plots from category level down to one supported object;
  expanded axis ranges can retain stale manual ticks; compound scientific
  annotations fragment into unrelated primitives; and unsupported or
  semantically ambiguous objects do not have an explicit preserve/lock policy.
- Migration units:
  1. replace flat editable state with a serializable document, scene hierarchy,
     selection, style cascade, and command history while preserving FIG and
     popout handoff;
  2. add independent axis-limit, locator, formatter, and per-tick-label state,
     plus complete title, subtitle, ruler-label, legend, colorbar, and free-text
     editing;
  3. add adapters for the graphics and compound roles exercised by current
     LabKit App renderers, with explicit locked pass-through behavior for an
     unsupported native object;
  4. add object/category editing, layers, grouping, annotations, direct
     manipulation, exact panel geometry, shared-axis multi-panel layout, and
     align/distribute operations;
  5. unify preview, FIG/vector/raster export, editable package generation,
     style import/export, and preflight around the same effective document.
- Focused evidence: Figure Studio state, source, presentation, result, and
  product specifications; renderer fixtures covering every current LabKit App
  plot archetype; deterministic visual evidence at declared output geometry;
  hidden-GUI selection and direct-manipulation checks; App conformance and
  project dependency guardrails.
- Completion criteria: every migration unit is represented by current source,
  public documentation, and passing owned evidence; formulas, source data,
  units, and App-owned plot meaning remain unchanged; preview and all exports
  consume the same effective document; unsupported objects are retained or
  explicitly reported without silent loss.
- Removal condition: delete this ledger after the final Figure Studio version,
  manual, structured history, focused evidence, and pre-PR validation describe
  only the accepted semantic editor contract with no transitional path left.

## Maintaining the ledger

Open an entry only for a concrete current problem with an owner, observable
effect, focused test, completion criteria, and removal condition. Do not copy a
completed audit, supported behavior inventory, speculative cleanup, file-size
concern, or possible future abstraction into this file.

When an entry is resolved, delete it and any debt-only guardrail in the same
change. Preserve durable decisions and evidence in the owning manual and
component history.
