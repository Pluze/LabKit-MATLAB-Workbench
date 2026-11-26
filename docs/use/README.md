# Use LabKit

```labkit-page
id: use
type: tutorial
audience: new-user
summary: Install or update LabKit, open the Launcher, choose an App, and find the current guide for your workflow.
```

Follow these steps to install LabKit and open your first App. If you are changing the source code, start with [Develop LabKit](../develop/README.md).

## Requirements

- A supported Base MATLAB installation. LabKit production Apps do not require optional MathWorks Toolboxes. For NI instrument acquisition, see the [NI-DMM Recorder requirements](apps/electrical-measurement/ni-dmm-recorder/README.md) for the supported Windows driver and hardware.
- Internet access for the first launcher download or update. Installed packages run offline unless an app's own input lives on a network drive. Production apps do not create Python or Conda environments, download model weights, or install third-party packages on first use.

## Install And Launch

1. Download the latest [`labkit_launcher.m`](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases/latest/download/labkit_launcher.m).
2. Put it in a standalone folder such as `LabKit/`.
3. Open MATLAB in that folder.
4. Run:

```matlab
labkit_launcher
```

On your first run, follow the installation prompts. Once LabKit is installed, the launcher shows the Apps you can open. Keep experimental data and exported results outside the LabKit runtime folder. See the [LabKit Launcher manual](apps/labkit-core/launcher/README.md) for every button, programmatic mode, discovery rule, and maintenance action.

For a specific release, a rollback, or recovery from an interrupted update, follow [Upgrade or roll back LabKit](upgrade.md).

## Open An App

Select an App and click **Open Selected App**. The session log shows startup progress. If the App cannot start, look there for the error message.

Use the [App catalog](apps/README.md) to choose a workflow and confirm its input and output formats.

## Common App Commands

Click **LabKit ▾** at the upper left of the App window to open the tools menu.

- **Copy Main Plots** copies the current workspace plots.
- **Copy Current Interface** copies the complete App window as an image.
- **LabKit ▾ > Diagnostics > Open Session Log...** shows messages from the current session. Filter by severity, or turn on TRACE capture if you need more detail while reproducing a problem.

To resume work later, check the App guide for a project save option. Use the App’s export controls for results you want to use elsewhere. For troubleshooting after the App closes, look for its session log under `artifacts/logs/sessions/`.

## Source Checkout

Clone the repository only when you need source development, tests, profiling, or review:

```bash
git clone https://github.com/Pluze/LabKit-MATLAB-Workbench.git
cd LabKit-MATLAB-Workbench
```

In MATLAB, open the cloned folder and run `buildtool headless` for the headless test suite. See [Testing](../develop/testing.md) for other build tasks.
