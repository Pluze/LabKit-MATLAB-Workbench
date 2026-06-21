# Agent Migration Ledger

This is the agent-facing migration debt ledger for LabKit. It is not an
architecture manual, validation matrix, historical changelog, or roadmap.

Human-facing architecture and app behavior live in `docs/`. Exact validation
commands live in `docs/testing.md` and are routed through
`labkit-test-planner`. This ledger owns only active migration debt facts,
retirement rules, and the minimum standard for handling future migration debt.

## Lifecycle

Update this ledger only when migration debt is added, reduced, retired, or
reprioritized. Keep it aligned with:

- current capability-style project guardrails
- `AppPackageStructureGuardrailTest` app package and UI 2.0 structure checks
- `docs/architecture.md` when human-facing boundary facts change

When debt is retired, remove stale ledger entries and shrink this file in the
same change. A completed migration should not remain as active roadmap text.

## Current Debt Snapshot

Current active migration debt:

```text
none
```

Current facts:

- Oversized app entry points: none.
- Oversized package-root app `run.m` runners over 500 lines: none.
- App `private/` debt: none.
- `+labkit` private helper contract debt: none.
- String-dispatch workflow adapters and app `+core/dispatch.m` routers: none.
- No active runner maps exist.
- Supported app entry points launch through `labkit.ui.app.create` directly or
  through app-owned package-root `run.m` orchestration.
- Migrated apps keep ordinary data-only specs in
  `+<app_slug>/+ui/buildSpec.m`, route extracted production code through
  role-based app-owned component packages, and avoid generic helper buckets.
- The public app-facing UI surface is the layered
  `labkit.ui.app/spec/view/tool/diag` foundation documented in `docs/ui.md`.

## Migration Standard

Apps are first-class products. `+labkit` stays a small domain-neutral foundation
with UI, DTA, RHS, and biosignal facades. App-specific calculations, summaries,
plots, exports, workflow wording, file conventions, and result schemas stay
under the owning app tree.

A healthy runner owns orchestration only: launch/debug wiring, shell assembly,
state coordination, callback registration, alerts, log wording, and refresh
ordering.

Extract only behavior that becomes clearer and directly testable, and only when
the real GUI path calls the extracted helper. Use app-owned packages for
app-specific deterministic behavior. Use `labkit-boundary-guard` before moving
anything into `+labkit`.

Do not create new app `private` runners, root legacy command wrappers,
`*Workflow.m` adapters, app `+core/dispatch.m` routers, or convenience public
packages such as `+labkit/+analysis`, `+io`, `+data`, or `+util`.

## Future Debt Rules

- If guardrails detect new migration debt, update this ledger and the affected
  source or tests together.
- If debt inventory is empty, prefer shrinking this ledger over adding roadmap
  prose, scripts, or new governance layers.
- Keep completed migrations as historical baselines only when they clarify a
  current guardrail invariant.
- Use `labkit-test-planner` for validation routing and `docs/testing.md` for
  exact commands.
