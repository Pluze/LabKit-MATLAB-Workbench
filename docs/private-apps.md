# Private Apps

LabKit supports local private app workspaces for apps that should not be
published in the public repository. This page documents only the public
extension point, folder shape, and development contract. Private app names,
workflow notes, data assumptions, validation details, and release notes belong
in the private app repository itself.

## Workspace Location

In a LabKit source checkout, create an ignored `private_apps/` workspace:

```text
LabKit-MATLAB-Workbench/
  apps/                  public apps tracked by this repository
  +labkit/               shared LabKit facades
  private_apps/          local private app workspace, ignored here
    apps/
      <private_family>/
        <app_slug>/
          labkit_<PrivateAppName>_app.m
          +<app_slug>/
            definition.m
            definitionActions.m
            requirements.m
            version.m
            +appLifecycle/createInitialState.m
            +userInterface/buildWorkbenchLayout.m
            +userInterface/updateWorkbenchFromState.m
            +sourceFiles/...
            +analysisRun/...
            +resultFiles/...
```

The launcher also reads additional private workspaces from
`LABKIT_PRIVATE_APP_ROOTS`. Each entry can point either at a private workspace
root or directly at its `apps/` folder. Separate multiple entries with the
platform path separator.

## Launcher Discovery

The launcher discovers:

- public app entry points under `apps/**/labkit_*_app.m`
- private app entry points under `private_apps/apps/**/labkit_*_app.m`
- private app entry points under `LABKIT_PRIVATE_APP_ROOTS`

Private entries appear in the app catalog with `Visibility` set to `private`.
They launch like ordinary LabKit apps after the launcher adds the app folder to
the MATLAB path.

## Git Ownership

Keep `private_apps/` as a separate private Git repository:

```bash
cd LabKit-MATLAB-Workbench
mkdir private_apps
cd private_apps
git init
git remote add origin git@github.com:<owner>/<private-repo>.git
```

The public LabKit repository ignores `private_apps/`, so private app files are
not added to public history, public release zips, or public CI. Do not use a
submodule unless you intentionally want the public repository to record a
private remote URL and commit pointer.

## Structure Rules

Private apps should follow the same app-owned package shape as public apps:

- keep one public entrypoint named `labkit_<PrivateAppName>_app.m`
- keep app workflow code under the owning `+<app_slug>/` package
- use `definition.m`, `definitionActions.m`, `requirements.m`, and `version.m`
- keep lifecycle state in `+appLifecycle`
- keep data-only layout and visible-state updates in `+userInterface`
- group workflow code by concrete user capability, such as `+sourceFiles`,
  `+analysisRun`, `+resultFiles`, or another app-owned domain package
- use shared LabKit facades such as `labkit.ui.*`, `labkit.image.*`,
  `labkit.thermal.*`, `labkit.dta.*`, `labkit.rhs.*`, and
  `labkit.biosignal.*`

Do not put private app source under public `apps/`. Do not move private
workflow formulas, private result schemas, private labels, or private data
assumptions into `+labkit`.

## Private Documentation

The public repository should contain only this generic private-app structure
guide. Put private app catalogs, SOPs, validation commands, sample notes,
deployment notes, and release history in the private app repository.
