# App tools and presentation controls become more deliberate

```labkit-change
schema: 2
id: LK-20260720-app-tools-menu-and-screenshot-clipboard
date: 2026-07-20
sequence: 141
type: feat
compatibility: compatible
component: `labkit.app` | `1.1.0 -> 1.2.0`
scope: App Framework
scope: All tracked Apps
```

## Context

Plot, Screenshot, Save State, and Load State appeared as separate root-level
native menu items. Plot was a container while the other items executed
immediately, so controls at the same visual level had inconsistent behavior
and consumed unnecessary horizontal space. Screenshot also required a file
dialog even when the user only needed an image for another application. Short
status summaries consumed the same height as detail panels, and Apps could
preserve plot zoom but had no declarative one-shot reset revision.

## Decision and rationale

Install one framework-owned **Tools** root with purpose-based **Plots**,
**Screenshot**, and conditional **Project State** submenus. Keep scientific
workflow controls in the App layout while grouping domain-neutral native
utilities predictably. Use MATLAB's existing `copygraphics` clipboard path so
the capability remains platform-neutral and introduces no external runtime.

## Changes

- Moved plot utilities beneath **Tools > Plots**.
- Added **Tools > Screenshot > Copy to Clipboard** for the complete App
  surface and retained file export as **Save to File...**.
- Moved project persistence beneath **Tools > Project State** when the App
  owns a project document.
- Preserved existing executable action tags for compatibility with GUI
  automation and added stable tags for the new menu containers and clipboard
  action.
- Added a line-count hint for compact status summaries and a general
  plot-view revision that accepts renderer-fitted limits once while preserving
  user zoom during ordinary redraws.
- Updated the getting-started and framework manuals.

## Compatibility and user impact

App calculations, project files, plots, and exports are unchanged. Existing
action tags continue to identify save screenshot, save state, load state, and
plot commands, but users now reach them through the Tools hierarchy. Clipboard
copy uses the operating system clipboard and may be unavailable in a
noninteractive MATLAB session.

## Validation and evidence

- Hidden native-adapter GUI coverage verifies the menu hierarchy, labels,
  conditional Project State menu, stable action tags, and clipboard callback
  wiring.
- Focused framework tests validate the App SDK version and native runtime.
- Documentation rendering and consistency checks cover the updated manuals and
  history record.

## Follow-up

Developer-led interactive checks should confirm clipboard image fidelity and
native menu appearance on supported MATLAB desktop platforms.
