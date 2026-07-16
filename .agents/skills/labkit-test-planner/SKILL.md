---
name: labkit-test-planner
description: "Use for validation planning, MATLAB test execution, pre-commit checks, CI scope, GUI checks, fixtures, or test-runner changes."
---

# LabKit Test Planner

## Read

Read `AGENTS.md`, `tests/AGENTS.md`, affected source/tests, and
`docs/development/testing.md` when exact tasks or routing matter. Do not reread
shared context already inspected for another active skill.

## Select evidence

Start with the smallest suite that exercises the changed owner:

```text
labkit_framework/<area>           reusable facade behavior
apps/<family>                     app logic and exports
gui/labkit_framework/ui           framework GUI and interactions
gui/apps/<family>/<app_slug>      one app workflow/layout
gui/project/launcher              launcher behavior
project/<topic>                   repository contracts
```

Use focused `runLabKitTests` during iteration, `changedFast` at a coherent
checkpoint, and `changed` once for stable handoff. Pair facade changes with
downstream apps when their contract can be affected. After a failure, repair
and rerun the narrowest failed test; broaden again only when the fix crosses
another boundary or final policy requires it.

For private workspaces, run private tests first. The acceptance sentinel opts
private source into public scans but does not expose its Git diff to the public
planner, so invoke the relevant public guardrail explicitly.

Run MATLAB with host permission in sandboxed sessions. Keep broad GUI runs
hidden and avoid them while the user is actively interacting with the desktop.
Never automate manual native-dialog or pointer workflows in `-batch`.

## Claims

- Non-GUI tests do not validate GUI behavior.
- Structural GUI tests validate launch/layout/callback wiring.
- Workflow GUI tests validate bounded synthetic flows.
- Debug tests validate diagnostics, not usability.
- Native dialogs, visual quality, pointer feel, real data, and scientific
  validity remain manual unless a dedicated deterministic test proves them.

Report MATLAB availability, exact commands/results, GUI/manual status,
unverified behavior, and why any expected gate was intentionally omitted.
