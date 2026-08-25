# Launcher and maintainer tool manuals

```labkit-change
id: CHG-20260716-launcher-and-maintainer-manuals
date: 2026-07-16
type: docs
compatibility: compatible
component: labkit_launcher
```

## Why

Launcher behavior was split between Getting Started, architecture notes, source comments, and historical records. Maintainer tools under `tools/` had callable MATLAB entry points but no coherent manual set; profiling details were embedded in the testing command matrix while packaging and codecheck behavior were mostly discoverable only from source.

### Accepted choice

Document the user-operated launcher beside LabKit Core apps, even though its self-repair implementation remains a root-level standalone file. Document source-checkout tools under Development because they support maintenance rather than app workflows. Keep the existing Testing page as the test-system owner, add a conceptual execution map there, and move profiler call details into the maintainer tool reference.

This structure lets readers start from the product they operate or the maintenance task they intend, without mirroring every source directory or mixing tool APIs into reusable `labkit.*` function reference.

## What changed

- Added a LabKit Launcher manual covering window actions, programmatic calls, discovery, installation, recovery, tools, limitations, and development milestones.
- Added a maintainer-tool landing page and detailed references for Code Analyzer reports, app deployment packages, documentation builds, and performance profiling.
- Added a test-system execution map explaining build tasks, runner discovery, test layers, selectors, plugins, artifacts, and manual-validation boundaries.
- Connected Getting Started, Apps, LabKit Core, Development, Architecture, Documentation, Testing, Release, the root README, and generated navigation to the new manuals.

## Impact

Users can now understand launcher controls and history from the Apps section. Maintainers can copy direct MATLAB calls and inspect every supported option and output without reading tool implementation files. No app workflow, scientific calculation, saved project, input file, or exported result changes.

## Compatibility and limits

This is an additive documentation change. Existing page URLs remain valid. The new launcher and tool pages are generated from Markdown and included in search; no handwritten HTML or third-party documentation package is added.

### Remaining limits

Private app documentation remains in each private repository. Internal private helpers beneath tool folders are intentionally described through their public entry point rather than receiving standalone reference pages.
