# Architecture Notes

This document describes the current package boundaries and compatibility layers. It is not a roadmap.

## Core Shape

```text
app entry points / legacy-compatible GUI entry points
    ↓
package-backed app internals or preserved legacy GUI implementations
    ↓
struct-based item/session models
    ↓
+gamrywb package functions
```

The package owns reusable parsing, data access, analysis, plotting helpers, export helpers, session helpers, and small utilities. GUI files own layout, callbacks, user prompts, alerts, and display wiring.

## Compatibility Entrypoints

Root-level commands preserve the original MATLAB names:

```text
gamry_CIC_VT_gui_paperlabels
gamry_VT_resistance_gui
gamry_CV_CSC_dta_gui
gamry_EIS_multiDTA_plot_gui
gamry_multiDTA_plot_export_gui
```

They are thin wrappers that add `legacy/` to the path only when needed and call the matching `_legacy.m` implementation.

`apps/gamrywb_EIS_app.m` and `apps/gamrywb_CSC_app.m` are package-backed and do not delegate to legacy. The CIC and VT resistance `apps/gamrywb_*_app.m` files are compatibility entry points that still delegate to the preserved legacy GUIs.

`startup_gamrywb` does not add `legacy/` to the default path. This keeps legacy code out of the normal runtime path while preserving original command compatibility through root wrappers.

## Legacy GUI Layer

Files under `legacy/` are preserved behavior references and compatibility targets. They may call package helpers, but they still own:

- layout construction
- UI controls and callbacks
- file dialogs and user alerts
- log-panel text
- result display wiring
- GUI-specific annotations

Do not add new scientific formulas, parser variants, or CSV formatting logic there unless preserving an existing GUI behavior requires it.

## Package Responsibilities

```text
+gamrywb/+io        DTA parsers, folder discovery, export table construction, session IO
+gamrywb/+data      item/session construction and table/column access
+gamrywb/+analysis  pulse detection and scientific analysis
+gamrywb/+plot      reusable plot helpers that accept axes and data
+gamrywb/+ui        reusable UI display-data helpers
+gamrywb/+util      small generic helpers
```

Package functions should not depend on GUI state or call `uialert`.

Analysis functions should return status through result structs, for example:

```matlab
result.ok = false;
result.message = "Not enough valid T/Vf/Im points.";
```

The GUI decides how to display that status.

## Current Package Surface

- `+io`: chrono, EIS, and CV/CT parsers; chrono/EIS/VT/CIC/CV-CSC result table builders; VT/CIC legacy-format CSV writers; session save/load.
- `+data`: table/column accessors, CV/CT selected-column access, chrono item construction, EIS item construction, session add/remove helpers.
- `+analysis`: pulse detection, pulse-gap alignment, VT resistance, CIC, CV/CSC, EIS axis-value generation, batch summaries.
- `+plot`: chrono VT/IT overlay, CV/CT selected-column plotting, EIS overlay plotting.
- `+ui`: VT resistance and CIC batch table display data.
- `+util`: low-risk helpers used by parser, data, analysis, and export code.

## Boundaries To Preserve

Avoid:

- analysis functions reading UI controls
- package functions writing directly to GUI text areas
- new parser copies in GUI files
- duplicated CSV formatting in GUI files
- MATLAB classes before struct schemas stabilize
- replacing remaining CIC and VT resistance compatibility app delegates before schemas and validation are ready
- starting a unified GUI before package-backed app internals are stable
