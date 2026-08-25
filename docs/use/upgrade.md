# Upgrade Or Roll Back LabKit

```labkit-page
id: use-upgrade
type: task
audience: app-user
summary: Review a published LabKit version, preserve user-owned data, upgrade safely, verify the workflows you depend on, or return to an earlier release.
```

Use the Launcher to install a published LabKit version without moving project files, source data, or exports into the replaceable installation folder.

## Before You Upgrade

- Save work and close every LabKit App.
- Keep source data, projects, and exports outside the LabKit installation.
- Read the target version under [GitHub Releases](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases), especially its upgrade guidance and known limitations.
- Custom App authors should also review [framework compatibility](../develop/framework/compatibility/contracts.md).

## Upgrade

Open `labkit_launcher`, choose **Versions**, select a published Release, and read its summary before installation. Choose **Latest** only when you want the newest published stable Release. Update a source checkout with Git rather than replacing it through the Launcher.

## Verify

Reopen the Launcher and confirm its displayed version. For every App you depend on, complete its shortest normal workflow: open a representative input, confirm the expected result, and export to a user-owned location. Use the owning [App guide](apps/README.md) for current behavior.

## Roll Back

Open **Versions**, select the earlier published Release, review its compatibility note, and install it. A rollback does not rewrite external laboratory files or exports. If an App-owned saved format requires migration, follow that App's current guide and the selected Release note.

## Recover An Incomplete Installation

Close every App and run:

```matlab
labkit_launcher("repair")
```

Report a problem when repair cannot establish a complete installation or when the current App guide says a saved project is supported but the selected Release cannot open it.

## Related Topics

- [Use LabKit](README.md)
- [LabKit Launcher](apps/labkit-core/launcher/README.md)
- [GitHub Releases](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases)
- [Support](../../.github/SUPPORT.md)
