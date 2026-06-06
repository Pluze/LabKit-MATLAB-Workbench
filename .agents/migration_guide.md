# Agent Migration Ledger

This is the agent-facing zero-debt ledger for LabKit migrations. It is not an
architecture manual, validation matrix, or historical changelog.

Human-facing architecture and app behavior live in `docs/`. Exact validation
commands live in `docs/testing.md` and are routed through `labkit-test-planner`.
This ledger owns only migration debt facts, retirement rules, and the minimum
standard for handling future migration debt.

## Lifecycle

Update this ledger when migration debt is added, reduced, retired, or
reprioritized. Keep it aligned with:

- `ProjectDebtGuardrailTest.expectedOversizedRunnerDebtFiles`
- `ProjectDebtGuardrailTest.expectedAppPrivateDebtFiles`
- `ProjectDocumentationGuardrailTest.expectedPrivateContractDebtFiles`
- `ProjectStructureGuardrailTest` package and startup path checks
- `docs/architecture.md` for human-facing boundary facts

When debt is retired, remove stale expected-debt entries and shrink this file in
the same change. A completed migration should not remain as active roadmap text.

## Current Debt Snapshot

Current active migration debt:

```text
none
```

Current facts:

- Oversized app entry points: none.
- Oversized app `+ui/runApp.m` runners over 500 lines: none.
- App `private/` debt: none.
- `+labkit` private helper contract debt: none.
- String-dispatch workflow adapters and app `+core/dispatch.m` routers: none.

Completed migration baseline: ECG Print, DIC Preprocess, DIC Postprocess, CIC
runner normalization, and CSC runner normalization are complete. Treat them as
guarded baselines, not active phases.

No active runner maps exist. If a future guardrail records new runner debt, add
only a narrow map for the specific file and delete it when the debt is retired.

## Migration Standard

Apps are first-class products. `+labkit` stays a small domain-neutral foundation
with UI, DTA, and biosignal facades. App-specific calculations, summaries,
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

- If guardrails detect new migration debt, update the matching expected-debt
  inventory, this ledger, and the affected source or tests together.
- If debt inventory is empty, prefer shrinking this ledger over adding roadmap
  prose, scripts, or new governance layers.
- Keep completed migrations as historical baselines only when they clarify a
  current guardrail invariant.
- Use `labkit-test-planner` for validation routing and `docs/testing.md` for
  exact commands.
- After any completion push, inspect CI. If required CI fails, read only failing
  job logs, fix the cause, rerun the relevant local check, push again, and
  repeat until CI passes or an infrastructure/access blocker is explicit.
