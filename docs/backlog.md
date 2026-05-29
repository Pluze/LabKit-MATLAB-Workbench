# Backlog

This document records useful future directions and deferred work for Gamry Electrochemistry Workbench.

These are **not active refactor requirements**.

Do not start these features before the behavior-preserving MATLAB package refactor reaches v1.0 unless explicitly requested.

---

## 1. Before Starting Future Features

Future features should confirm the v1.0 package-refactor gate remains true:

```text
[x] legacy GUIs are preserved and verified
[x] common parser functions are stable for legacy-supported file families
[x] common analysis functions are stable for current v1.0 workflows
[ ] normalized item/result/option schemas are stable enough for new app work
[x] session and export workflow conventions are stable for current legacy-compatible workflows
[x] fixture coverage exists for current legacy-supported Gamry DTA experiment types
[x] CIC can run without GUI
[x] VT resistance can run without GUI
[x] CV/CSC can run without GUI
[x] EIS overlay/export can run without GUI
[x] reference tests exist for major outputs
```

The active refactor goal remains:

```text
same results
less duplicate code
clearer boundaries
safer future changes
```

---

## 2. Session-Based Workflow

Future idea:

- Extend the current explicit session save/load support.
- Store raw parsed data, selected analysis mode, options, results, and notes.
- Allow rerunning analysis after changing options.
- Preserve file provenance and analysis settings.

Current implemented helpers include:

```text
+gamrywb/+data/makeSession.m
+gamrywb/+io/saveSession.m
+gamrywb/+io/loadSession.m
```

Design rule:

- Keep session fields explicit.
- Avoid opaque object dumps for long-term scientific data.

---

## 3. Batch Analysis Pipeline

Future idea:

- Run analysis over folders without opening a GUI.
- Support batch CIC, VT resistance, CV/CSC, and EIS extraction.
- Export standardized summary tables.
- Reuse the same package functions as GUI apps.

Candidate entry points:

```text
scripts/run_batch_chrono_analysis.m
scripts/run_batch_eis_export.m
scripts/run_batch_csc_analysis.m
```

These names may change. Batch entry points should be implemented only after analysis functions are decoupled from GUI state and session/export conventions are stable.

---

## 4. Golden Reference Regression System

Future idea:

- Save expected outputs for representative fixtures.
- Compare package-backed results against legacy-generated outputs.
- Track tolerances per metric.
- Detect accidental scientific behavior changes.

Possible reference files:

```text
tests/reference/cic_expected.mat
tests/reference/vt_resistance_expected.mat
tests/reference/csc_expected.mat
tests/reference/eis_expected.mat
tests/reference/chrono_overlay_expected.mat
```

This is a high-value future improvement and should be prioritized before large UI rewrites.

---

## 5. Unified Workbench GUI

Future idea:

Create one integrated GUI after the library layer is stable.

Potential structure:

```text
Gamry Workbench
├── file/session panel
├── analysis mode selector
│   ├── Chrono Overlay
│   ├── CIC / Voltage Transient
│   ├── VT Resistance
│   ├── CV / CSC
│   └── EIS Overlay
├── mode-specific settings panel
├── result summary table
├── plot area
└── log panel
```

Important rule:

- Do not start this before parser, data, analysis, plotting, and export helpers are stable.
- Do not start this before the generic DTA document parsing layer, normalized item/result/option schemas, session/export workflow, and fixture-driven validation are stable.
- Phase 10 app entry points are compatibility delegates today; a unified GUI remains blocked until package-backed thin app internals are stable.
- A premature unified GUI would create a larger monolithic GUI and make the project worse.

---

## 6. Publication Figure Export

Future idea:

- Add publication-quality figure export presets.
- Standardize line widths, font sizes, axis labels, units, and figure dimensions.
- Support paper, supporting information, and presentation presets.
- Export both MATLAB figures and high-resolution image files.

Possible package area:

```text
+gamrywb/+plot
```

This should reuse existing plot helpers rather than duplicating plotting logic.

---

## 7. EIS Fitting Extension

Future idea:

- Add equivalent-circuit fitting or Cole-model fitting for EIS data.
- Keep raw EIS parser and plotting separate from model fitting.
- Store fit options, initial guesses, bounds, and fit quality metrics explicitly.

Potential outputs:

```text
R0
Rinf
tau
alpha
fit residuals
fit quality metrics
```

This should not be mixed with the basic EIS parser/overlay refactor.

---

## 8. MATLAB Project and Packaging

Future idea:

- Add MATLAB Project `.prj` support.
- Add shortcuts for launching apps and running tests.
- Add MATLAB Compiler packaging for lab-internal distribution.

Packaging should wait until:

- app entry points stabilize
- package dependencies are known
- test fixtures and validation checks are available

---

## 9. Optional Python Migration

Future idea:

- Migrate pure analysis modules to Python only after MATLAB behavior is stable.
- Use MATLAB package outputs and golden references as source of truth.
- Keep GUI and hardware-control needs separate from analysis translation.

Do not use Python migration as a reason to change MATLAB behavior during the current refactor.

---

## 10. Plugin-Like Support for New Gamry Experiment Types

Future idea:

- Add support for new Gamry DTA experiment types through explicit parser modules.
- Avoid creating one overly clever parser too early.
- Add fixtures before supporting new file variants.

Potential pattern:

```text
parseDTA dispatches by TAG/TITLE/table structure
specific parsers handle specific experiment families
analysis modules consume normalized item structs
```

Treat names in this pattern as candidate design vocabulary, not API commitments. Add representative DTA fixtures and schema expectations before adding support for a new experiment family.

---

## 11. Out of Scope for Now

The following are intentionally out of scope during the current behavior-preserving refactor:

```text
full application redesign
new scientific metrics not present in legacy behavior
new stimulation protocol design
cloud/web dashboard
Python rewrite
real-time hardware control refactor
MATLAB class hierarchy
plugin framework
commercial packaging
```

These may be reconsidered after v1.0.

---

## 12. Entrypoint Cleanup Candidates

The root-level compatibility wrappers and preserved legacy GUI implementations must remain in place until a separate entrypoint-removal task performs GUI smoke tests and manual MATLAB launch checks.

Possible future cleanup:

- Audit legacy-directory compatibility shims for redundancy.
- Decide whether any shim can be removed without breaking documented command names.
- Keep the original root-level legacy command names runnable unless a future release explicitly deprecates them.
