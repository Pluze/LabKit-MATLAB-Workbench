# App diagnostics persist errors and distinguish informational dialogs

```labkit-change
id: LK-20260804-automatic-error-diagnostic-bundles
date: 2026-08-04
sequence: 174
type: feat
compatibility: compatible
component: `labkit.app` | `2.2.0 -> 2.3.0`
component: `labkit_ECGPrint_app` | `1.6.2 -> 1.6.3`
scope: Error-triggered diagnostic persistence
scope: Compact diagnostic state default
scope: Informational callback dialogs
```

## Context

Runtime already enabled TRACE after the first ERROR or CRITICAL event, but the
user still had to export the session before closing the App. Diagnostic export
also defaulted to the exact MAT option even though decoded caches can make that
bundle unnecessarily large. Separately, `CallbackContext.alert` always used
the native error icon, and one successful ECG timetable export used that
failure-oriented operation for its completion notice.

## Decision and rationale

Remember whether the session ever records ERROR or CRITICAL independently of
the bounded in-memory event window and the current TRACE toggle. After close
cleanup and its terminal lifecycle event are recorded, automatically export a
compact-state diagnostic bundle when that error flag is set. Keep clean closes
side-effect free and keep diagnostic persistence failure from changing Runtime
close semantics. Use compact state as the default for manual and automatic
exports while preserving exact state as an explicit manual choice.
Add the explicitly named `CallbackContext.inform` capability for successful or
neutral information and keep `CallbackContext.alert` error-styled for blocking
problems. The repository scan found 80 App alert calls: 79 describe missing
prerequisites or failures and remain alerts; the one successful ECG timetable
notice moves to `inform`.

## Changes

- Runtime remembers whether ERROR or CRITICAL occurred for the full session,
  independent of the bounded event view and current TRACE toggle.
- Closing an affected App automatically writes one compact diagnostic bundle
  after the close lifecycle result is recorded.
- Manual diagnostic export defaults to compact state and retains exact state
  as an explicit choice.
- `CallbackContext.inform` presents successful and neutral information with an
  information icon; ECG timetable workspace export now uses it.
- App authoring policy reserves error-style `CallbackContext.alert` for
  blocking problems.

## User and data impact

Closing an App after an error writes one uniquely named ZIP beneath
`artifacts/diagnostics/`. It includes complete sensitive retained events and a
structurally compact `app-state-compact.mat`; it is diagnostic evidence rather
than scientifically valid saved state. Sessions without ERROR or CRITICAL
events do not create a close-time bundle. Users can still explicitly select an
exact-state bundle.
The ECG workspace timetable completion notice now uses an information icon;
its export data and workspace variable are unchanged.

## Compatibility and migration

The additive callback capability is compatible with existing version-2 App SDK
requirements. Existing `alert` calls keep their error styling. Project schemas
and result files do not change, and no project migration is required. ECG Print
1.6.3 raises its App SDK requirement to `>=2.3 <3` because it calls the new
`inform` capability.

## Validation

Focused headless App SDK diagnostics specifications cover compact defaults,
automatic export after an error, inclusion of the completed close event, and
the absence of automatic output for a clean close. Existing exact, compact,
journal-degradation, and text-fallback bundle contracts remain covered.
App SDK source evidence distinguishes `inform` and `alert` backend operations;
the ECG hidden-GUI workflow verifies the successful workspace export uses the
native information icon.

## Evidence

- `SessionDiagnosticBundleSpec` passed 8/8 focused headless identities.
- `AppSdkSpec` passed 23/23 focused App SDK identities.
- `EcgPrintWorkflowSpec` passed its focused hidden-GUI workflow identity.
- Authored-link validation checked 259 Markdown files with no unresolved
  links; deterministic documentation validation compared 387 generated files.

## Known limitations and follow-up

A process termination that bypasses Runtime close cannot create the close-time
bundle; the durable session journal remains the surviving evidence boundary.
Both compact and exact bundles may contain sensitive paths, filenames,
scientific values, and exception details.
