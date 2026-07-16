# Getting Started

This guide covers the shortest path from an empty folder to a running LabKit
app. For source development, continue with the
[development guide](../development/README.md).

## Requirements

- A supported MATLAB installation.
- Internet access for the first launcher download or update. Installed source
  and P-code packages run offline unless an app's own input lives on a network
  drive.
- Any MathWorks products declared by the selected app. The launcher shows app
  requirements before launch.

Production apps do not create Python or Conda environments, download model
weights, or install third-party packages on first use.

## Install And Launch

1. Download the latest
   [`labkit_launcher.m`](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases/latest/download/labkit_launcher.m).
2. Put it in a standalone folder such as `LabKit/`.
3. Open MATLAB in that folder.
4. Run:

```matlab
labkit_launcher
```

The launcher can install or update the runtime, discover available apps, and
start the selected app. Keep experimental data and exported results outside
the LabKit runtime folder.

## Choose A Version

- **Release** installs the latest stable GitHub release.
- **Latest** installs the current `main` branch.
- **Versions** selects a recent release, tag, or commit for a deliberate
  upgrade or rollback.

Before replacing an installed runtime, the launcher moves its current contents
to a dated `LabKit-previous-*` folder. This provides a local recovery point but
is not a substitute for backing up lab data.

## Open An App

Select one row in the launcher and choose **Open**. The launcher prepares the
MATLAB path, checks reusable facade requirements, and displays startup progress
until the app is ready.

Use the [app catalog](../apps/README.md) to choose a workflow and confirm its
input and output formats.

## Common App Commands

Every current LabKit app exposes these top-level entries:

- **Screenshot** captures the active app surface.
- **Save State** writes the current project document.
- **Load State** opens a compatible project document.
- **Plot** contains plot-specific actions such as opening a larger editable
  view when the current axes supports them.

State files preserve app projects. They are different from exported result
files and from ignored debug manifests under `artifacts/debug/`.

## Source Checkout

Clone the repository only when you need source development, tests, profiling,
or review:

```bash
git clone https://github.com/Pluze/LabKit-MATLAB-Workbench.git
cd LabKit-MATLAB-Workbench
buildtool headless
```

See [Testing](../development/testing.md) before choosing a broader build task.

## Next Steps

- [App guide](../apps/README.md)
- [Public API reference](../libraries/README.md)
- [Development guide](../development/README.md)
