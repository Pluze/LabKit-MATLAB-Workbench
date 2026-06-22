# LabKit MATLAB Workbench

[![Release](https://img.shields.io/github/v/release/Pluze/LabKit-MATLAB-Workbench?label=release)](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases)
[![MATLAB Tests](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml/badge.svg)](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![MATLAB](https://img.shields.io/badge/MATLAB-apps-orange.svg)](https://www.mathworks.com/products/matlab.html)

Focused MATLAB GUI apps for lab workflows.

LabKit gives lab users a launcher-first way to open small, purpose-built apps
for electrochemistry, DIC, image measurement, wearable biosignals, and
neurophysiology. Each app owns its workflow, plots, result tables, and exports.
The reusable `+labkit` foundation stays small: GUI shell helpers, Gamry DTA
loading, Intan RHS loading, and biosignal processing facades.

## Start Here

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

## What You Get

- A single launcher that can start from a folder containing only
  `labkit_launcher.m`.
- Independent apps with stable public commands and app-owned workflow logic.
- A small shared foundation for GUI shells, DTA loading, RHS loading, and
  biosignal processing.
- Generated artifacts kept separate from source data and exported results.

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

## Find The Right Page

| I want to | Go to |
| --- | --- |
| Open LabKit or pick an app | [docs/apps.md](docs/apps.md) |
| Understand the documentation set | [docs/README.md](docs/README.md) |
| Report a problem or ask for workflow support | [.github/SUPPORT.md](.github/SUPPORT.md) |
| Change source code or run checks | [docs/testing.md](docs/testing.md) |
| Understand package and app boundaries | [docs/architecture.md](docs/architecture.md) |
| Prepare a public release | [docs/release.md](docs/release.md) |

## Development

Clone the repository when you need to change source code or run tests:

```bash
git clone https://github.com/Pluze/LabKit-MATLAB-Workbench.git
cd LabKit-MATLAB-Workbench
buildtool headless
```

See [docs/testing.md](docs/testing.md) for the supported build tasks and GUI
validation limits.

## Project Shape

```text
apps/      workflow-specific MATLAB GUI apps
+labkit/   reusable UI, DTA, RHS, and biosignal facades
docs/      human-facing usage, API, architecture, and validation docs
tests/     behavior tests, project contracts, GUI checks, and runner code
```

Apps are the deliverables. Shared code moves into `+labkit` only when it is
domain-neutral, app-facing, tested, and useful beyond one workflow.

## License

This project is open source under the MIT License. See [LICENSE](LICENSE).
