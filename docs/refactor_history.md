# Refactor History

This file keeps only the historical context that is still useful when reading older commits. Current usage belongs in `README.md`; current boundaries belong in `docs/architecture.md`.

## v1.0 Checkpoint

The v1.0 behavior-preserving refactor extracted the original MATLAB GUI workflows into package-backed helpers while preserving scientific behavior, GUI behavior, parser behavior, pulse detection, and CSV/export formats.

At that checkpoint, several migration surfaces still existed:

- public parser/file IO under `+gamrywb/+io`
- item/session/data access helpers under `+gamrywb/+data`
- public analysis and plotting helper packages
- root-level compatibility wrappers for original GUI command names
- a preserved `legacy/` reference directory

Those were useful migration scaffolds, not the final architecture.

## Later Cleanup

Post-v1.0 cleanup removed the legacy runtime dependency and narrowed the app-facing package surface:

- current runtime entry points are the `apps/<category>/gamrywb_*_app.m` files
- app-specific analysis, plotting, result-table, and CSV/export behavior lives in the owning app file
- reusable GUI infrastructure lives under `gamrywb.ui.*`
- DTA discovery, loading, sessions, pulse detection, parser/session IO, and parsed table/curve access live behind `gamrywb.dta.*`
- parser, item/session, pulse, and table-scanning helpers are private DTA implementation details
- public `+io`, `+data`, `+analysis`, `+plot`, `+util`, `+app`, and app-helper namespaces were removed

## Behavior Preserved

The refactor preserved the validated behavior for:

- chrono T/Vf/Im/Pt interpretation and metadata parsing
- EIS ZCURVE parsing and supported axis values
- CV/CT SCANRATE conversion and curve parsing
- pulse detection modes and compatibility fields
- VT resistance, CIC, and CSC calculations
- EIS and chrono overlay plotting/export behavior
- GUI layout contracts and CSV/export column names

## Remaining Historical Risk

The main historical risk is coverage, not known functional drift: tests use named demo fixtures and fixed reference values, but not every legacy GUI workflow has stored golden MAT output. Manual GUI checks are still required for file dialogs, export buttons, loaded-data workflows, plot interactions, and user alerts.
