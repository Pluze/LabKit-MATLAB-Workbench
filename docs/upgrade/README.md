# Upgrade Or Roll Back LabKit

```labkit-page
id: upgrade
type: task
audience: app-user
summary: Choose a published LabKit version, review compatibility, upgrade safely, or return to an earlier release.
```

## Goal

Install a published LabKit version while preserving projects and laboratory data outside the installation folder.

## Before You Upgrade

- Save work and close every LabKit App.
- Keep source data, projects, and exports outside the LabKit installation.
- Read the target version under [GitHub Releases](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases), especially its upgrade guidance and known limitations.
- Custom App authors should also review [framework compatibility](../develop/framework/compatibility/contracts.md).

## Upgrade

Open `labkit_launcher`, choose **Versions**, select a published release, and review its information before installation. Use **Latest** only when you want the newest published release. Git checkouts are updated with Git rather than replaced by the Launcher.

## Verify

Reopen the Launcher, confirm the displayed version, and run the shortest normal workflow in the App you depend on. Confirm that expected inputs open and that results can be exported to a user-owned location.

## Roll Back

Open **Versions**, select the earlier published release, review its compatibility note, and install it. A rollback does not rewrite external laboratory files or exports. If a saved project format requires migration, follow the owning App's current manual and the target release note.

## Recover

If installation is incomplete, close every App and use the Launcher's repair action. Report a problem when the Launcher cannot establish a complete installation or when a current manual's supported project cannot be opened.

## Related

- [Start](../start/README.md)
- [Launcher](../apps/labkit-core/launcher/README.md)
- [GitHub Releases](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases)
- [Support](../../.github/SUPPORT.md)
