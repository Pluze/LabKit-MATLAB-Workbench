# Launcher startup is sortable and measurable

```labkit-change
id: CHG-20260903-launcher-timed-startup-log
date: 2026-09-03
type: feat
compatibility: compatible
component: labkit_launcher | 2.0.1 -> 2.1.0
```

## Why

The Launcher reported only coarse startup status, so a slow App open could not be separated into Launcher discovery, path preparation, App invocation, and App-owned runtime construction. The App table also remained fixed in discovery order even when users needed to scan by family, name, version, access, or update date.

The accepted choice is a small Launcher-owned diagnostic record rather than reusing App session journals: Launcher work begins before an App runtime exists, and the two lifecycles need independent timing. Native table sorting preserves the underlying row identity, so launch and package selection continue to address the correct App after the visible order changes.

## What changed

- Every App-table column supports native ascending and descending sorting from its heading.
- The Launcher records bounded structured timings for its own view, discovery, tool probing, path preparation, and App invocation stages.
- **View Launch Log** shows the current session record, while the standard artifact folder retains the 20 most recent Launcher logs.
- App invocation no longer forces a second synchronous full-window paint before returning control to MATLAB.
- `labkit_launcher` advances from 2.0.1 to 2.1.0.

## Impact

Users can organize the catalog without changing which App a selected row opens and can distinguish Launcher overhead from App-owned initialization or rendering. The Launcher becomes responsive once the App entry point returns; the App window may continue painting normally on MATLAB's event loop.

## Compatibility and limits

Programmatic Launcher calls and App entry points are unchanged. Logs intentionally omit paths, filenames, exception messages, and scientific values. A synchronous App entry point can still block MATLAB until it returns, and an App's own runtime log remains the authority for its internal construction and presentation stages.
