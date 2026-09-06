---
name: labkit-performance-profiler
description: "Use for measured LabKit startup, callback, file-loading, or launcher performance work and profileLabKitTarget reports. Performance conclusions require representative measurements rather than inspection alone."
---

# LabKit Performance Profiler

Read `AGENTS.md`, the measured source path, nearby tests, and `docs/develop/tools/profiling.md`. Use
`labkit-boundary-guard` if ownership moves and `labkit-test-planner` for
validation.

Run a narrow scenario with `profileLabKitTarget`, `OpenReport=false`, and an
explicit target. Record the artifact path and distinguish normal from debug
launch. Start with JSON `summaryText`/`AGENT_SUMMARY`; inspect function rows and
parent/child edges only when needed. Source tags mean:

- `project`: editable checkout code;
- `matlab_internal`: MATLAB implementation;
- `external`: other code;
- `profiler_tool`: measurement overhead.

Profile startup, close, chooser callbacks, Run, and Export as separate
scenarios. Use synthetic inputs. GUI creation has variance, so confirm a shared
framework conclusion with representative repeated runs and focused behavior
tests. Do not optimize a path merely because it has high total time while it
waits for user input or figure close.

Change only the owner of the measured cost. Report scenario, before/after
evidence, code changes, tests, and any unverified interactive behavior.
