# LabKit MATLAB Workbench

[![Release](https://img.shields.io/github/v/release/Pluze/LabKit-MATLAB-Workbench?label=release)](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases)
[![MATLAB Tests](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml/badge.svg)](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![MATLAB](https://img.shields.io/badge/MATLAB-apps-orange.svg)](https://www.mathworks.com/products/matlab.html)

LabKit is a MATLAB workbench for small, focused lab GUI apps. It is organized
around independent workflows rather than one large analysis platform. Apps own
their scientific choices, plots, result tables, and exports. The reusable
`+labkit` library stays small: GUI shell helpers, Gamry DTA loading, Intan RHS
loading, and biosignal processing facades.

## Start Here

Open MATLAB at the repository root and run:

```matlab
labkit_launcher
```

The launcher scans `apps/**/labkit_*_app.m`, shows the available tools, and
opens the selected app. It also has direct actions for Debug launch, updating
non-git installs from the GitHub `main` zip, MATLAB Code Analyzer reporting,
and cleaning generated artifacts.

Start apps from the launcher in normal use. To launch an app command manually,
first add the repository root, `apps/`, and the target app folder to the MATLAB
path, then call the app command.

Use the launcher's `Run Code Analyzer` action when you want an ignored
`artifacts/code-check/matlab_code_check.json` report.

Use `Update from GitHub` only for zip-download installs. The updater is
disabled in git checkouts. It overwrites LabKit-managed files from GitHub
`main`, preserves user files that are not project files, and writes a visible
`LabKit-backup-*.zip` in the project root before changing files.

## Contributor Quick Path

1. Open MATLAB at the repository root and run `labkit_launcher`.
2. Read [docs/README.md](docs/README.md) to choose the one or two docs that
   match your task.
3. Make the smallest source change that preserves the owning app or facade
   boundary.
4. Before committing, use the changed-file validation task from
   [docs/testing.md](docs/testing.md). Use the full non-GUI task when there is
   no git checkout or changed-file state.

## App Families

| Family | Examples | Purpose |
| --- | --- | --- |
| Electrochemistry | `labkit_CIC_app`, `labkit_EIS_app`, `labkit_VTResistance_app` | Gamry DTA review, metrics, plots, and exports. |
| DIC | `labkit_DICPreprocess_app`, `labkit_DICPostprocess_app` | Image preparation, ROI masks, strain overlays, and summaries. |
| Image measurement | `labkit_CurvatureMeasurement_app`, `labkit_FocusStack_app`, `labkit_ImageEnhance_app`, `labkit_BatchImageCrop_app` | Image measurement, microscopy utilities, and figure preparation. |
| Wearable biosignal | `labkit_ECGPrint_app` | ECG import, filtering, peak/segment review, and exports. |
| Neurophysiology | `labkit_RHSPreview_app`, `labkit_NerveResponseAnalysis_app`, `labkit_ResponseReviewStats_app` | Intan RHS inspection, channel protocol drafting, manual filter records, event-locked nerve response analysis, and aligned response statistics. |

## Validate Locally

Default non-GUI check:

```bash
buildtool headless
```

If `buildtool` is not available in your shell, find your MATLAB app and add its
`bin` directory to `PATH`, then rerun the same command:

```bash
ls /Applications/MATLAB_*.app/bin/matlab
export PATH="/Applications/MATLAB_R2025a.app/bin:$PATH"
```

See [docs/testing.md](docs/testing.md) for the supported build tasks and GUI
validation limits.

## Repository Map

```text
+labkit/                Reusable UI, DTA, RHS, and biosignal facades
apps/                   Launchable app workflows and app-owned helpers
docs/                   Human-facing usage, architecture, and API docs
scripts/                CI/report helper scripts
tests/                  Unit, contract, GUI, shared helpers, and runner code
```

## Documentation

- [docs/README.md](docs/README.md): choose the right document.
- [docs/apps.md](docs/apps.md): app catalog, new-app workflow, app structure.
- [docs/architecture.md](docs/architecture.md): ownership boundaries.
- [docs/testing.md](docs/testing.md): build tasks and GUI limits.
- [docs/ui.md](docs/ui.md), [docs/dta.md](docs/dta.md),
  [docs/rhs.md](docs/rhs.md), and [docs/biosignal.md](docs/biosignal.md):
  reusable facade references.

## License

This project is open source under the MIT License. See [LICENSE](LICENSE).
