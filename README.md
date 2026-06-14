# LabKit MATLAB Workbench

[![Release](https://img.shields.io/github/v/release/Pluze/LabKit-MATLAB-Workbench?label=release)](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases)
[![MATLAB Tests](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml/badge.svg)](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![MATLAB](https://img.shields.io/badge/MATLAB-apps-orange.svg)](https://www.mathworks.com/products/matlab.html)

LabKit is a MATLAB workbench for small, focused lab GUI apps. It is organized
around independent workflows rather than one large analysis platform. Apps own
their scientific choices, plots, result tables, and exports. The reusable
`+labkit` library stays small: GUI shell helpers, Gamry DTA loading, and
biosignal processing facades.

## Start Here

Open MATLAB at the repository root and run:

```matlab
labkit_launcher
```

The launcher scans `apps/**/labkit_*_app.m`, shows the available tools, and
opens the selected app. It also has direct actions for Debug launch, Project
Governance, and cleaning generated artifacts. Known apps can also be launched
directly, for example:

```matlab
labkit_CIC_app
labkit_DICPreprocess_app
labkit_ImageEnhance_app
labkit_ECGPrint_app
```

Use `labkit_ProjectGovernance_app` when you want to create a new app scaffold
or scan the project with MATLAB Code Analyzer.

## App Families

| Family | Examples | Purpose |
| --- | --- | --- |
| Electrochemistry | `labkit_CIC_app`, `labkit_EIS_app`, `labkit_VTResistance_app` | Gamry DTA review, metrics, plots, and exports. |
| DIC | `labkit_DICPreprocess_app`, `labkit_DICPostprocess_app` | Image preparation, ROI masks, strain overlays, and summaries. |
| Image measurement | `labkit_CurvatureMeasurement_app`, `labkit_FocusStack_app`, `labkit_ImageEnhance_app`, `labkit_BatchImageCrop_app` | Image measurement, microscopy utilities, and figure preparation. |
| Wearable biosignal | `labkit_ECGPrint_app` | ECG import, filtering, peak/segment review, and exports. |
| Project tools | `labkit_ProjectGovernance_app` | New-app scaffolding and project code checks. |

## Validate Locally

Default non-GUI check:

```bash
buildtool test
```

If MATLAB is not on `PATH`, use the locator:

```bash
scripts/matlab_batch.sh "buildtool test"
```

The locator writes its MATLAB log to `artifacts/logs/matlab_batch/matlab.log`.

See [docs/testing.md](docs/testing.md) for focused selectors and GUI checks.

## Repository Map

```text
+labkit/                Reusable UI, DTA, and biosignal facades
apps/                   Launchable app workflows and app-owned helpers
docs/                   Human-facing usage, architecture, and API docs
scripts/                Shell/Python support utilities for MATLAB batch runs and CI summaries
tests/                  Unit, contract, GUI, shared helpers, and runner code
```

## Documentation

- [docs/README.md](docs/README.md): choose the right document.
- [docs/apps.md](docs/apps.md): app catalog, new-app workflow, app structure.
- [docs/architecture.md](docs/architecture.md): ownership boundaries.
- [docs/testing.md](docs/testing.md): build tasks, selectors, GUI limits.
- [docs/ui.md](docs/ui.md), [docs/dta.md](docs/dta.md), and
  [docs/biosignal.md](docs/biosignal.md): reusable facade references.

## License

This project is open source under the MIT License. See [LICENSE](LICENSE).
