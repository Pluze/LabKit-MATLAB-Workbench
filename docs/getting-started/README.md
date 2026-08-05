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
the LabKit runtime folder. See the [LabKit Launcher manual](../apps/labkit-core/launcher/README.md)
for every button, programmatic mode, discovery rule, and maintenance action.

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
MATLAB path, checks the app's LabKit version requirements, and displays startup
progress until the app is ready.

Use the [app catalog](../apps/README.md) to choose a workflow and confirm its
input and output formats.

## Common App Commands

Every current LabKit app exposes one top-level **Tools** menu:

- **Tools > Plots** contains plot-specific actions such as opening larger
  editable views, copying plots, and saving plots.
- **Tools > Screenshot > Copy to Clipboard** copies the complete active App
  surface as an image.
- **Tools > Screenshot > Save to File...** saves the complete App surface.
- **Tools > Project State > Save State...** writes the current project
  document.
- **Tools > Project State > Load State...** opens a compatible project
  document.
- **Tools > Diagnostics > Open Session Log...** opens the current App's named
  live log with Full TRACE, DEBUG, and User views.
- **Tools > Diagnostics > Export Diagnostic Bundle** asks for exact or compact
  synthetic App state, defaults to compact, then writes complete sensitive
  logs plus the selected MAT in an automatically named ZIP beneath
  `artifacts/diagnostics/`. After an ERROR or CRITICAL event, closing the App
  automatically writes the compact bundle there.

State files preserve app projects. They are different from exported result
files and from ignored diagnostic manifests under `artifacts/diagnostics/`.

## Source Checkout

Clone the repository only when you need source development, tests, profiling,
or review:

```bash
git clone https://github.com/Pluze/LabKit-MATLAB-Workbench.git
cd LabKit-MATLAB-Workbench
buildtool headless
```

See [Testing](../development/maintain-and-release/testing.md) before choosing a broader build task.

## Next Steps

- [App guide](../apps/README.md)
- [LabKit Launcher](../apps/labkit-core/launcher/README.md)
- [Public API reference](../reference/README.md)
- [Development guide](../development/README.md)
