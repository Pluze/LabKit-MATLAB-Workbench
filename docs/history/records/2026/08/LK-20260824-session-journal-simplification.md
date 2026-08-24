# Session journals become the direct diagnostic record

```labkit-change
id: LK-20260824-session-journal-simplification
date: 2026-08-24
sequence: 192
type: refactor
compatibility: compatible
component: `labkit.app` | `3.0.0 -> 3.1.0`
scope: App session logging
scope: Diagnostic artifact simplification
```

## Context

The App runtime retained a canonical session journal and then repackaged the same event history with a compact App-state projection into diagnostic ZIP files. The live panel also accumulated search, category, action, audience-oriented level modes, clear-view state, and cross-session export paths even though retained logs are primarily consumed by maintainers and analysis agents.

## Decision and rationale

Use the structured session folder as the single retained diagnostic and usage-history artifact. Keep the current-session viewer intentionally small, with one minimum-severity filter and an independent manual TRACE capture control. This preserves the event evidence needed to diagnose failures and understand App activity while removing a second packaging and state-projection system.

## Changes

- New session folder names include the App ID, UTC start time, and a unique suffix; the manifest now also identifies the App version, LabKit App SDK version, and MATLAB release.
- The live viewer now filters only by minimum severity from TRACE through CRITICAL and no longer exposes search, category, action, audience-mode, or clear-view controls.
- TRACE capture remains manual and no longer starts automatically after an ERROR or CRITICAL record.
- Diagnostic ZIP, compact App-state, text-fallback, automatic-on-close, and previous-active-session export workflows were retired.

## User and data impact

App calculations, callback APIs, event records, result exports, and saved task formats are unchanged. Users and maintainers inspect `manifest.json` and `events-*.jsonl` directly beneath `artifacts/logs/sessions/`; no new diagnostic ZIPs or App-state copies are created. Existing session folders and previously exported bundles are not changed or deleted.

## Compatibility and migration

The change is compatible with existing App definitions and callback logging calls. Existing session directories remain readable and require no migration; only newly created folder names and manifests include the additional discovery metadata. Code that depended on private diagnostic export methods is outside the supported App SDK contract.

## Validation

Focused headless journal, event-stream, projection, runtime-instrumentation, and hidden-GUI viewer specifications cover the retained event contract, manual TRACE behavior, severity-only panel, descriptive session identity, and manifest metadata. Documentation and repository policy checks cover the current manuals and structured history.

## Evidence

The source specifications verify that errors do not enable TRACE, severity filtering does not mutate canonical history, removed ZIP controls are absent, and default session folders remain correlated with their manifest and JSONL records.

## Known limitations and follow-up

LabKit does not provide a cross-session browser, database, replay engine, automatic retention policy, or generic App-state reconstruction. Retained folders remain user-managed artifacts, and events can describe only operations that entered Runtime or were explicitly logged by App callbacks.
