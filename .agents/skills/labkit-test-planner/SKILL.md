---
name: labkit-test-planner
description: "Use for validation planning, MATLAB test execution, pre-commit checks, CI scope, GUI checks, fixtures, or test-runner changes."
---

# LabKit Test Planner

## Read

Read `AGENTS.md`, `tests/AGENTS.md`, affected source/tests, and
`docs/development/maintain-and-release/testing.md` when exact tasks or routing
matter. Do not reread shared context already inspected for another active
skill.

## Select evidence

Keep the calling model small:

- before PR preparation, use focused tests for the current small branch step;
  run `changedFast` once at the review-ready checkpoint. PR and main-push CI
  own the complete validation;
- use the platform-independent skill-owned wrapper at
  `.agents/skills/labkit-test-planner/scripts/runLabKitTestTarget.m` instead
  of rebuilding runner argument lists. It is not in the repository-root
  `scripts/` folder. Add that exact skill folder to the MATLAB path once, then
  call:

  ```matlab
  addpath(".agents/skills/labkit-test-planner/scripts")
  ```

  - `runLabKitTestTarget("list-file", File=path)` to print canonical names;
  - `runLabKitTestTarget("run-file", File=path)` for one exact file;
  - `runLabKitTestTarget("run-test", Test="Class/method")` for an exact
    method; add `File=path` only to constrain an ambiguous owner;
  - `runLabKitTestTarget("run-suite", Suite=path, Gui=true)` only when a
    folder scope is necessary.

The wrapper locates the repository from its own path, infers GUI inclusion for
files and `gui/` suites, uses hidden GUI mode, disables focused HTML reports,
and preserves the official runner's fail-on-zero-match behavior. Read the
script only when changing or diagnosing the wrapper. Use the existing
cross-platform `buildtool changedFast` command for the local final gate; do not
wrap it.

Choose by execution cost as well as matched-test count. One GUI method may
launch a real App, parse files, redraw several times, and export outputs, so it
is not a cheap iteration test merely because the runner reports one match.

Use this escalation order:

1. pure helper or calculation test;
2. direct presenter, renderer, state-transition, or callback test;
3. one structural GUI method for wiring that cannot be proved below the UI;
4. one complete App workflow after the smaller behaviors are stable;
5. branch/repository gates only during PR or final integration preparation.

When a GUI workflow longer than roughly 20 seconds fails, use its stack and
artifacts to reproduce the failing helper, renderer, callback, or presentation
value directly. Do not rerun the whole workflow until that narrower check
passes. Combine corrected behaviors into one final GUI run instead of
rerunning after every edit.

Migration source scanners require semantic fixtures: ordinary local helpers
must not become UI callbacks, definition values must not become field names,
and every generated aggregate must agree on category uses and App unions.

Common folder scopes are:

```text
labkit_framework/<area>           reusable facade behavior
apps/<family>                     app logic and exports
gui/labkit_framework/ui           framework GUI and interactions
gui/apps/<family>/<app_slug>      one app workflow/layout
gui/project/launcher              launcher behavior
project/<topic>                   repository contracts
```

Do not make callers learn internal validation-plan names or test-discovery
implementation. Pair facade changes with downstream apps when
their contract can be affected. After a failure, copy the canonical
`Class/method` name from runner output and use `run-test`; the wrapper resolves
the unique owning file from the class name.
Keep broad execution single-process unless a repeatable end-to-end benchmark
shows a material wall-clock gain after worker startup, discovery, reporting,
and tail latency. Estimated per-test parallelism is not evidence by itself;
include CPU, licensing, platform behavior, live status, and failure diagnosis
in the decision, and remove orchestration that does not repay those costs.
Repair and rerun the narrowest failed behavior, which may be a smaller direct
test than the method that exposed it; broaden again only when the fix crosses
another boundary or final policy requires it. A zero-match result is a
selection failure, not passing evidence: use `list-file`, then rerun with the
printed name.

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
