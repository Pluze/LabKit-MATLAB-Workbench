# LabKit MATLAB Workbench

[![Release](https://img.shields.io/github/v/release/Pluze/LabKit-MATLAB-Workbench?label=release)](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases)
[![MATLAB Tests](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml/badge.svg)](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![MATLAB](https://img.shields.io/badge/MATLAB-apps-orange.svg)](https://www.mathworks.com/products/matlab.html)

LabKit is a MATLAB workbench for focused lab GUI apps. Each app owns its lab
workflow, plots, result tables, and exports. The reusable `+labkit` foundation
stays small: GUI shell helpers, Gamry DTA loading, Intan RHS loading, and
biosignal processing facades.

## Quick Start

Download the single-file launcher:

**[Download `labkit_launcher.m`](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases/latest/download/labkit_launcher.m)**

1. Create a standalone folder for LabKit, for example `LabKit/`.
2. Save `labkit_launcher.m` in that folder.
3. Open MATLAB in that folder and run:

```matlab
labkit_launcher
```

Use `Latest` in the launcher to update from the current `main` branch, or
`Release` to use the latest stable GitHub release. Keep lab data and exported
results in your own project folders; the LabKit folder can be treated as an
application runtime folder.

## Why Use The Launcher

- It is the stable entry point for opening every LabKit app.
- It can start from a folder that only contains `labkit_launcher.m`.
- It downloads or updates the LabKit code for normal users.
- It keeps users away from repository layout details during routine use.

A git checkout is only needed for source development, testing, CI work, or
reviewing implementation details.

## App Families

| Family | Examples | Purpose |
| --- | --- | --- |
| Electrochemistry | `labkit_CIC_app`, `labkit_EIS_app`, `labkit_VTResistance_app` | Gamry DTA review, metrics, plots, and exports. |
| DIC | `labkit_DICPreprocess_app`, `labkit_DICPostprocess_app` | Image preparation, ROI masks, strain overlays, and summaries. |
| Image measurement | `labkit_CurvatureMeasurement_app`, `labkit_FocusStack_app`, `labkit_ImageEnhance_app`, `labkit_BatchImageCrop_app` | Image measurement, microscopy utilities, and figure preparation. |
| Wearable biosignal | `labkit_ECGPrint_app` | ECG import, filtering, peak/segment review, and exports. |
| Neurophysiology | `labkit_RHSPreview_app`, `labkit_NerveResponseAnalysis_app`, `labkit_ResponseReviewStats_app` | Intan RHS inspection, channel protocol drafting, filter records, event-locked nerve response analysis, and aligned response statistics. |

See [docs/apps.md](docs/apps.md) for the full app catalog and expected inputs
and outputs.

## Documentation

Start with [docs/README.md](docs/README.md). It separates normal app usage from
maintainer references so the homepage does not need to expose the whole
repository structure.

Useful direct links:

- [App catalog and launch notes](docs/apps.md)
- [Architecture and ownership boundaries](docs/architecture.md)
- [Testing and validation tasks](docs/testing.md)
- [Release policy](docs/release.md)

## Development

Clone the repository when you need to change source code or run tests:

```bash
git clone https://github.com/Pluze/LabKit-MATLAB-Workbench.git
cd LabKit-MATLAB-Workbench
buildtool headless
```

See [docs/testing.md](docs/testing.md) for the supported build tasks and GUI
validation limits.

## License

This project is open source under the MIT License. See [LICENSE](LICENSE).
