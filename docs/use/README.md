# Use LabKit

```labkit-page
id: use
type: tutorial
audience: new-user
summary: Install or update LabKit, open the Launcher, choose an App, and find the current guide for your workflow.
```

Start here when you want to run LabKit rather than change its source. This guide takes you from an empty folder to a running App and points to the complete App catalog; source developers can continue with [Develop LabKit](../develop/README.md).

## Requirements

- A supported Base MATLAB installation. LabKit production Apps do not require optional MathWorks Toolboxes.
- Internet access for the first launcher download or update. Installed packages run offline unless an app's own input lives on a network drive. Production apps do not create Python or Conda environments, download model weights, or install third-party packages on first use.

## Install And Launch

1. Download the latest [`labkit_launcher.m`](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases/latest/download/labkit_launcher.m).
2. Put it in a standalone folder such as `LabKit/`.
3. Open MATLAB in that folder.
4. Run:

```matlab
labkit_launcher
```

The launcher can install or update the runtime, discover available Apps, and start the selected App. Keep experimental data and exported results outside the LabKit runtime folder. See the [LabKit Launcher manual](apps/labkit-core/launcher/README.md) for every button, programmatic mode, discovery rule, and maintenance action.

## Choose A Version

- **Latest** installs the latest published stable GitHub Release.
- **Versions** shows published stable Releases and their release information, and installs the selected Release for a deliberate upgrade or rollback.

Before replacing an installed runtime, the launcher moves its current contents to a dated `LabKit-previous-*` folder. This provides a local recovery point but is not a substitute for backing up lab data.

For a deliberate version change, follow [Upgrade or roll back LabKit](upgrade.md) to review the published Release, preserve user-owned data, verify the workflows you depend on, and recover an incomplete installation.

## Open An App

Select one row in the launcher and choose **Open**. The launcher prepares the MATLAB path, and the App checks its declared LabKit facade versions before creating a window. Startup progress remains visible until the App is ready.

Use the [App catalog](apps/README.md) to choose a workflow and confirm its input and output formats.

## Common App Commands

Every current LabKit app exposes one top-level **Tools** menu:

- **Tools > Plots** contains plot-specific actions such as opening larger editable views, copying plots, and saving plots.
- **Tools > Screenshot > Copy to Clipboard** copies the complete active App surface as an image.
- **Tools > Screenshot > Save to File...** saves the complete App surface.
- **Tools > Diagnostics > Open Session Log...** opens the current App's named live log. Its minimum-severity selector ranges from TRACE through CRITICAL; TRACE capture is enabled manually when extra detail is needed.

Task save/open controls appear only in Apps whose workflow genuinely supports continuation. The framework has no Project State menu or archive. Each qualifying App owns its snapshot file and restores one current/final task state.

App-owned task snapshots are different from exported results and from the structured session journals under `artifacts/logs/sessions/`.

## Source Checkout

Clone the repository only when you need source development, tests, profiling, or review:

```bash
git clone https://github.com/Pluze/LabKit-MATLAB-Workbench.git
cd LabKit-MATLAB-Workbench
buildtool headless
```

See [Testing](../develop/testing.md) before choosing a broader build task.

## Next Steps

- [App catalog](apps/README.md)
- [LabKit Launcher](apps/labkit-core/launcher/README.md)
- [Upgrade or roll back LabKit](upgrade.md)
- [Public API reference](../reference/README.md)
- [Development guide](../develop/README.md)
