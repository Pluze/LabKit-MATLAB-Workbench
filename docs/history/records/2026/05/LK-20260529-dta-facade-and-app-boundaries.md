# DTA facade and app ownership boundaries

```labkit-change
id: LK-20260529-dta-facade-and-app-boundaries
date: 2026-05-29
sequence: 2
type: refactor
compatibility: compatible
scope: historical project evolution
```

## Context

The first extraction pass separated calculations from the imported GUIs, but
the electrochem apps still depended on a broad internal package and shared
session helpers. A new app could reuse a parser only by learning implementation
details that had nothing to do with reading a DTA file.

## Decision and rationale

Make DTA loading the reusable boundary and keep workflow decisions in the app
that owns them. The public layer would load one file, discover files, or load a
folder and return documented report structures. Plot labels, callback order,
session state, result summaries, and export choices would remain app concerns.

This distinction became an early form of LabKit's present architecture: a
small library presents stable data operations, while an app owns the laboratory
workflow assembled around those operations.

## Changes

- Added GUI-independent DTA loading and adopted it in the EIS and Chrono
  Overlay apps.
- Added discovery and folder-loading operations, including validation for
  empty selections, missing folders, and expected experiment kinds.
- Documented and tested the report schemas returned by batch operations.
- Moved EIS, Chrono Overlay, CSC, VT Resistance, and CIC out of the original
  `gamrywb` namespace and into app-owned entry points.
- Returned calculation details, labels, callback flow, and exports to their
  owning apps when they were not genuinely reusable.
- Introduced boundary tests to prevent UI, data, IO, analysis, and utility
  packages from growing through accidental cross-dependencies.

## User and data impact

Electrochem users kept the same principal workflows, but file-loading failures
became more explicit and batch loading gained a defined result report. App
authors could use the DTA layer without starting a GUI or depending on the
layout of an existing app.

No laboratory file format or scientific result schema was intentionally
changed by the ownership cleanup.

## Compatibility and migration

The supported app commands replaced direct use of the old `gamrywb` package.
Code that reached into that package's internal helpers needed to move either to
the DTA facade or into the app that owned the behavior.

## Validation

The period added DTA schema tests, empty- and missing-folder tests, architectural
boundary checks, and behavior-focused calculation tests. The repository did
not yet have the later unified MATLAB test command, so no single historical
validation invocation is available.

## Evidence

- GUI-free loading facade `88b19851` and initial app adoption `789ef507`,
  `0ccc3ad6`.
- App ownership migration `1ee8e82d` through `1b6042bf`.
- Discovery and folder loading `c06946d9`, `82f4146d`.
- Report documentation and contract tests `669eea38`, `e04292c0`.
- Boundary and failure-handling work from `ad2b6c74` through `7506fa32`.

## Known limitations and follow-up

The public surface was still organized around the first electrochem use cases.
The next stage renamed the workbench, narrowed the package map further, and
tested whether the same app-first approach could support image and biosignal
workflows.
