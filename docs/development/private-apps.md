# Private Apps

[Development index](README.md) | [App development](app-development.md)

LabKit supports local private app workspaces for apps that should not be
published in the public repository. This page documents only the public
extension point, folder shape, and development contract. Private app names,
workflow notes, data assumptions, validation details, and release notes belong
in the private app repository itself.

## Repository And Mounting Model

A private app workspace is its own Git repository. It owns its app source,
tests, manuals, histories, and repository rules regardless of where it is
stored. The public repository never owns or migrates those files.

For convenient local development, the independent repository may be checked
out at the public checkout's ignored `private_apps/` mount point:

```text
LabKit-MATLAB-Workbench/
  apps/                  public apps tracked by this repository
  +labkit/               shared LabKit facades
  private_apps/          independent private Git repository, ignored here
    README.md
    tests/
    apps/
      <private_family>/
        <app_slug>/
          README.md
          HISTORY.md
          labkit_<PrivateAppName>_app.m
          +<app_slug>/
            definition.m
            definitionActions.m
            requirements.m
            version.m
            +appLifecycle/createProject.m
            +appLifecycle/createSession.m
            +appLifecycle/validateProject.m
            +userInterface/buildWorkbenchLayout.m
            +userInterface/presentWorkbench.m
            +sourceFiles/...
            +analysisRun/...
            +resultFiles/...
```

That physical nesting is only a launcher mount; it does not make the private
repository a folder owned by the public repository. The private repository may
instead live anywhere and be registered through `LABKIT_PRIVATE_APP_ROOTS`.
Each entry points either to a private repository root containing `apps/` or
directly to its `apps/` folder. Separate entries with the platform path
separator.

## Launcher Discovery

The launcher discovers:

- public app entry points under `apps/**/labkit_*_app.m`
- private app entry points under `private_apps/apps/**/labkit_*_app.m`
- private app entry points under `LABKIT_PRIVATE_APP_ROOTS`

Private entries appear in the app catalog with `Visibility` set to `private`.
They launch like ordinary LabKit apps after the launcher adds the app folder to
the MATLAB path.

The launcher can also package a selected private app for offline deployment as
either source `.m` files or encoded `.p` files. The generated zip preserves the
private app under `private_apps/apps/...` and includes the packaged launcher
plus the deployment/profiling tool folders it uses. Private apps discovered
through `LABKIT_PRIVATE_APP_ROOTS` are copied into that same
`private_apps/apps/...` package shape so the zip does not depend on the source
machine's environment variable or private workspace path.

## Git Ownership

Create or clone the private repository independently, then choose either the
ignored mount point or the environment-variable registration:

```bash
cd LabKit-MATLAB-Workbench
mkdir private_apps
cd private_apps
git init
git remote add origin git@github.com:<owner>/<private-repo>.git
```

The public LabKit repository ignores its `private_apps/` mount point, so a
nested checkout remains a normal independent repository and is not added to
public history, public release zips, or public CI. Do not use a submodule
unless you intentionally want the public repository to record a private remote
URL and commit pointer.

## Structure Rules

Private apps should follow the same app-owned package shape as public apps:

- keep one public entrypoint named `labkit_<PrivateAppName>_app.m`
- keep app workflow code under the owning `+<app_slug>/` package
- use `definition.m`, `definitionActions.m`, `requirements.m`, and `version.m`
- keep lifecycle state in `+appLifecycle`
- keep the data-only layout and pure presenter in `+userInterface`
- group workflow code by concrete user capability, such as `+sourceFiles`,
  `+analysisRun`, `+resultFiles`, or another app-owned domain package
- use shared LabKit facades such as `labkit.ui.*`, `labkit.image.*`,
  `labkit.thermal.*`, `labkit.dta.*`, `labkit.rhs.*`, and
  `labkit.biosignal.*`

The minimal lifecycle files are `createProject.m`, `createSession.m`, and
`validateProject.m`. Versioned payloads add ordered migration files such as
`migrateProjectV1ToV2.m`; supported legacy top-level MAT variables add explicit
import functions. See [Build a Complete App](complete-app.md) for a working
file-by-file example and [Runtime and Lifecycle](../framework/runtime.md) for
every definition, project, session, action, presenter, and renderer field.

Do not put private app source under public `apps/`. Do not move private
workflow formulas, private result schemas, private labels, or private data
assumptions into `+labkit`.

## Private Documentation

The public repository should contain only this generic private-app structure
guide. Put private app catalogs, SOPs, validation commands, sample notes,
deployment notes, and release history in the private app repository.

Private app repositories own their own tests and validation runners. They do
not need to add app-specific suites, fixtures, build tasks, or sample assets to
the public LabKit repository. Private app internals may be looser than public
apps when a local workflow needs it, but the launcher-facing surface should
remain compatible with LabKit discovery and guardrails: keep launch commands,
`requirements` and `version` lightweight requests, path setup, and private
sample hygiene valid when the private workspace is present next to a public
checkout.

The public launcher's Code Analyzer tool includes configured private app
workspaces in local reports only after the private workspace opts in. Put an
empty `.labkit-accept-main-guardrails` file at the private workspace root to
accept the public repository's style and code-quality guardrails for that
workspace. When `private_apps/apps/` exists or `LABKIT_PRIVATE_APP_ROOTS`
points at an accepted private workspace, the generated
`artifacts/code-check/matlab_code_issues_*.json` and `.html` files include
those private app findings without adding private source to the public repo.
For one-off local checks, `LABKIT_GUARD_PRIVATE_APPS=1` temporarily includes
configured private roots even without the sentinel file.

Because private workspaces are separate Git repositories, public changed-file
tasks do not discover private diffs. For an accepted private workspace, run the
private repository's own tests and the public `buildtool changed` guardrail
before commit or handoff when private source, tests, docs, component history, or
version metadata changed.
