# Gamry Electrochemistry Workbench

MATLAB workbench for Gamry electrochemistry DTA analysis GUIs.

This repository is being refactored from several standalone MATLAB GUI files into a package-backed workbench while preserving legacy behavior.

## Getting Started

Run this from the repository root in MATLAB:

```matlab
startup_gamrywb
```

Then launch one of the compatibility entry points:

```matlab
gamry_multiDTA_plot_export_gui
gamry_EIS_multiDTA_plot_gui
gamry_CV_CSC_dta_gui
gamry_VT_resistance_gui
gamry_CIC_VT_gui_paperlabels
```

## Refactor Status

Phase 0-1 is in progress:

- Legacy GUI implementations are preserved under `legacy/`.
- Root-level compatibility wrappers keep the original GUI command names available.
- Low-risk shared utilities are available under `+gamrywb/+util/`.
- Scientific analysis, DTA parsing, plotting, and CSV export behavior are intentionally unchanged.
