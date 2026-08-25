# Session diagnostics expose actions and teardown failures

```labkit-change
id: CHG-20260726-actionable-session-diagnostics
date: 2026-07-26
type: fix
compatibility: compatible
component: labkit.app | 2.0.0 -> 2.0.1
```

## Why

The live session viewer exposed internal `Audience` and `Root` terminology without explaining their meaning. Root-action choices were bare `op-*` identifiers, so users could not tell which click or workflow event a correlated call chain represented. The TRACE-disabled notice also implied that ordinary lifecycle evidence might be missing even though only TRACE-severity records were disabled.

Runtime callback and startup failures were instrumented, but application resource cleanup ran before recorder close without its own operation boundary. A cleanup exception could therefore prevent orderly adapter and journal teardown while leaving no canonical lifecycle failure.

### Accepted choice

Present diagnostic concepts in user-task language while retaining stable machine identifiers underneath. Reader intent becomes **View**, root correlation becomes **Action**, and each action choice combines time, a safe semantic message or callback alias, and its `op-*` identifier.

Treat Runtime close as an ordinary instrumented lifecycle operation. Attempt independent resource and native cleanup even after one fails, persist the terminal close result, close the journal, and only then return the original or combined cleanup exception.

## What changed

- Replaced the viewer's Audience wording with Useful, Everything, User workflow, and Developer details choices plus explanatory tooltips.
- Replaced Root wording with Action and generated readable correlation labels without changing the underlying root-action filter value.
- Clarified that TRACE-off sessions still capture DEBUG lifecycle boundaries and every warning or error.
- Added `runtime.close.started`, `runtime.close.completed`, and `runtime.close.failed` operation records.
- Made sibling cleanup continue after a resource or adapter failure and guaranteed recorder close before the cleanup exception is returned.

## Impact

Users can select a recognizable action instead of guessing which `op-*` value belongs to an incident. Default views remain concise, while earlier DEBUG callback boundaries remain available without having enabled TRACE.

Scientific state, project data, App callbacks, and saved schemas are unchanged. Diagnostic records remain sanitized and use the existing bounded journal.

## Compatibility and limits

This is a compatible App SDK patch. Public App-author APIs and the event schema are unchanged. The projection adds a private display-label field, and existing root-action identifiers remain stable for filtering and exported bundles.

### Remaining limits

No logger can synthesize a failed terminal record for native events that never reach Runtime, exceptions deliberately swallowed without logging, or a process that hangs or terminates abruptly. The last retained boundary and journal lease state remain the evidence in those cases.
