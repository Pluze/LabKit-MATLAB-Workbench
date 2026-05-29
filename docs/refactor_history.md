# Refactor History

This is the single archived record of the completed v1.0 behavior-preserving package refactor. Current usage lives in `README.md`; current architecture, schemas, parser assumptions, and validation guidance live in the other docs.

## v1.0 Summary

The v1.0 refactor preserved the original MATLAB GUI workflows while extracting reusable package functions under `+gamrywb`.

Completed package areas:

- parsers and file discovery in `+gamrywb/+io`
- item/session construction and column access in `+gamrywb/+data`
- pulse detection and analysis functions in `+gamrywb/+analysis`
- reusable plot helpers in `+gamrywb/+plot`
- table-display helpers in `+gamrywb/+ui`
- low-risk generic helpers in `+gamrywb/+util`

Compatibility retained:

- preserved GUI implementations remain under `legacy/`
- `gamrywb_EIS_app`, `gamrywb_CSC_app`, and `gamrywb_VTResistance_app` are package-backed; the CIC app entry point delegates to a preserved legacy GUI
- `startup_gamrywb` keeps `legacy/` off the default runtime path

Later cleanup removed the root-level original command wrappers. The old command names are now reference history rather than default runtime entry points.

## Migration Highlights

- Moved preserved legacy GUI implementations into `legacy/` and added root-level wrappers.
- Removed legacy-directory same-name shims so `legacy/` contains only `_legacy.m` preserved implementations.
- Added `startup_gamrywb.m`.
- Extracted chrono, EIS, and CV/CT DTA parsers.
- Extracted common chrono item construction, pulse detection, and pulse-gap alignment.
- Extracted VT resistance, CIC / voltage-transient, CV/CSC, and EIS overlay/export helpers.
- Extracted legacy-format VT and CIC result/export table helpers.
- Added session creation, add/remove, save/load, and batch summary helpers.
- Added optional GUI compatibility tests for launch, initialized layout/control contracts, result tables, axes labels, and safe callbacks.

## Behavior Preserved

Chrono parsing:

- T/Vf/Im/Pt interpretation
- invalid row removal
- stable unique-time handling
- AREA, SAMPLETIME, ISTEP/VSTEP/TSTEP metadata parsing

Pulse detection:

- metadata-first and metadata-only modes
- current-only fallback where exposed
- fallback messages used by legacy behavior
- blank-gap-centered alignment and first-sample fallback

VT resistance:

- median current/voltage windows
- baseline-corrected and raw voltage modes
- result table columns and CSV format

CIC:

- Emc/Ema sampling
- 10 us default delay
- measured-current integration
- water-window presets
- area handling, safety classification, unit conversion, batch summary behavior

CV/CSC:

- sign-split integration
- zero-crossing handling
- recorded-time CT charge
- scan-rate-derived CV charge
- water-window trim behavior

EIS and chrono overlays:

- axis labels, log options, legends, grid behavior
- Nyquist/Bode behavior
- merged aligned-time export axis and interpolation
- CSV column names

## v1.0 Validation

The v1.0 package refactor is covered by the default MATLAB test suite:

```bash
scripts/run_matlab_tests.sh
```

The optional GUI compatibility contract is covered by:

```bash
scripts/run_matlab_tests.sh --gui
```

Default tests cover parser, data accessor, pulse detection, analysis, plotting helper, export table, session, UI-table helper, and app-entry resolution checks.

## Remaining Risks And Deferred Work

- Parser table-reading internals are still duplicated across parser families.
- Shared pulse detection targets the legacy single cathodic-first biphasic use case.
- Tests use demo fixtures and fixed reference values, but not every legacy GUI output has a stored golden MAT reference.
- The CIC app entry point remains a compatibility delegate; replacing it should wait for stable schemas and validation fixtures.
- Interactive GUI behavior beyond the optional noninteractive contract still needs manual checks.
- Normalized item/result/option schemas remain provisional bridges for future app internals.
