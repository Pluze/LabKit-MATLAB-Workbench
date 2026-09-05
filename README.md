# LabKit MATLAB Workbench

[![Release](https://img.shields.io/github/v/release/Pluze/LabKit-MATLAB-Workbench?label=release)](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases)
[![Continuous Integration](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/ci.yml/badge.svg)](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/ci.yml)
[![Documentation](https://img.shields.io/badge/docs-GitHub%20Pages-0969da)](https://pluze.github.io/LabKit-MATLAB-Workbench/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

LabKit is a collection of focused MATLAB Apps for laboratory analysis, measurement, and visualization. Open an App from one launcher to review data, inspect plots, and export results. Workflows include electrochemistry, DIC, image measurement, biosignals, gait, force gauges, and statistics.

Run Apps with Base MATLAB, or use documented MATLAB functions in your own scripts. Optional MathWorks Toolboxes are not required. The [complete documentation](https://pluze.github.io/LabKit-MATLAB-Workbench/) covers supported workflows, requirements, and development.

## Quick Start

1. **[Download `labkit_launcher.m`](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases/latest/download/labkit_launcher.m)** into a standalone folder such as `LabKit/`.
2. Open MATLAB in that folder and run:

   ```matlab
   labkit_launcher
   ```

3. Follow the launcher's installation prompts, then select and open an App.

Keep experimental data and exported results outside the LabKit installation folder. See [Use LabKit](https://pluze.github.io/LabKit-MATLAB-Workbench/use/) for installation and version guidance, or [open the current repository in MATLAB Online](https://matlab.mathworks.com/open/github/v1?repo=Pluze/LabKit-MATLAB-Workbench&file=labkit_launcher.m).

## Choose Your Goal

| I want to | Start here |
| --- | --- |
| Find an App for my data, understand its calculations and limits, or follow a workflow | [App catalog and guides](https://pluze.github.io/LabKit-MATLAB-Workbench/use/apps/) |
| Call analysis functions from MATLAB scripts or look up inputs and outputs | [API reference](https://pluze.github.io/LabKit-MATLAB-Workbench/reference/) |
| Build or extend an App, contribute code, test, or maintain a release | [Develop LabKit](https://pluze.github.io/LabKit-MATLAB-Workbench/develop/) |
| Understand why behavior changed | [Changes](https://pluze.github.io/LabKit-MATLAB-Workbench/changes/) |
| Report a problem or request a workflow | [Support and contributing](.github/SUPPORT.md) |

App guides own workflow details; the API reference owns exact function contracts. [GitHub Releases](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases) describe published versions and upgrade actions.

## Citation and License

For citation metadata, see the [Zenodo archive](https://zenodo.org/records/21250089) and [DOI: 10.5281/zenodo.21250088](https://doi.org/10.5281/zenodo.21250088). LabKit is open source under the [MIT License](LICENSE).
