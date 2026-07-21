# Debug workflows, launcher tools, and changelog governance

```labkit-change
id: LK-20260707-debug-workflows-launcher-tools-and-changelog-governance
date: 2026-07-07
sequence: 39
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.2.4 -> 1.2.5`
component: `labkit_launcher` | `1.2.5 -> 1.2.6`
component: `labkit_launcher` | `1.2.6 -> 1.2.7`
component: `labkit.ui` | `5.0.0 -> 5.0.1`
component: `labkit.ui` | `5.0.1 -> 5.0.2`
component: `labkit_DICPreprocess_app` | `1.3.4 -> 1.3.5`
component: `labkit_BatchImageCrop_app` | `1.6.6 -> 1.6.7`
component: `labkit_FocusStack_app` | `1.4.5 -> 1.4.6`
component: `labkit_FigureStudio_app` | `0.1.4 -> 0.1.5`
scope: Debug workflows, launcher tools, and changelog governance
```

## Context

The first complete debug sample packs exposed several false failures. A modal
file chooser could be mistaken for a stalled callback, DIC could read an older
ROI snapshot than the editor displayed, duplicate crops needed confirmation
before export, and Focus Stack's folder workflow was hard to reach from its
sample instructions.

The launcher was also becoming a practical maintenance and distribution tool.
Code Analyzer reports needed a durable home outside launcher source, individual
apps needed an offline package format, and private app workspaces needed to
remain discoverable without entering the public repository.

Finally, the growing changelog needed to explain the direction of the project,
not merely repeat tags and commit subjects.

## Decision and rationale

Use v3.1.0 as a stabilization release for reproducible debug workflows. Treat
native modal dialogs as active UI, read live editor state when it is newer than
the stored snapshot, and make required gestures visible in the app. Move code
analysis and packaging into dedicated tools, let the launcher invoke them, and
keep private app discovery separate from public release contents.

## Changes

- Release tag `v3.1.0`
- `labkit_launcher` `1.2.4 -> 1.2.7`
- `labkit.ui` `5.0.1 -> 5.0.2`
- `labkit_FigureStudio_app` `0.1.4 -> 0.1.5`
- `labkit_DICPreprocess_app` `1.3.4 -> 1.3.5`
- `labkit_BatchImageCrop_app` `1.6.6 -> 1.6.7`
- `labkit_FocusStack_app` `1.4.5 -> 1.4.6`

- DIC Preprocess ROI mask export now reads the live ROI editor anchors when
  building a mask, so preview/save do not misreport a drawn ROI as empty when
  editor state is newer than the app state snapshot.
- DIC Preprocess keeps the double-click ROI anchor workflow and makes the
  double-click requirement explicit in the visible details text.
- Batch Image Crop duplicate tasks now redraw with finite preview overlay
  coordinates while still requiring users to confirm the duplicated crop
  center before export.
- Figure Studio quick PNG/JPG/SVG export actions use runtime-compatible
  handler signatures.
- Focus Stack exposes a direct `Choose folder` action for loading all supported
  images from a focus-stack folder.
- Debug trace diagnostics no longer write stalled-callback crash reports while
  a file chooser modal is active.
- Moved the launcher Code Analyzer scan into `tools/codecheck`, which writes
  timestamped JSON/HTML report pairs under `artifacts/code-check/` without
  overwriting earlier runs.
- Added launcher actions and a deployment tool that package one selected LabKit
  app into a standalone zip, either as source `.m` files or encoded `.p` files.
- Added launcher discovery for local private app workspaces under
  `private_apps/apps/` and roots named by `LABKIT_PRIVATE_APP_ROOTS`.
- Clarified the public changelog model as a project evolution map organized by
  reader-facing evolution entries, with release tags and commits kept as
  anchors and evidence rather than the primary structure.

## User and data impact

The supplied debug packs could be followed without producing a false crash
report or an apparently disabled workflow. DIC mask export used the anchors
currently visible in the editor, duplicate crops remained blocked until their
centers were confirmed, and Focus Stack offered a direct folder action.

Maintainers gained timestamped HTML and JSON Code Analyzer reports. A selected
app could be packaged for production or offline use without tests, unrelated
apps, or repository metadata. Private apps could live beside the checkout,
appear in the ordinary launcher, and retain their own repository and history.

## Compatibility and migration

- DIC ROI editing still uses double-click to add anchors; no interaction-mode
  migration is required.
- Existing file-panel image selection remains available in Focus Stack.
- Code Analyzer report consumers should read the timestamped
  `artifacts/code-check/matlab_code_issues_*.json` files.
- Full LabKit checkout installs are unchanged. Single-app packages can start
  through either the packaged launcher or the direct run file; P-code packages
  require MATLAB to run the generated `.p` files.
- Public apps, public releases, and public CI remain scoped to `apps/`.

## Validation

PR #34 updated debug sample, ROI, crop, folder-loading, launcher-tool,
deployment, and private-workspace tests before its squash merge. Tag `v3.1.0`
points to release commit `9db01952`; the exact local command sequence was not
recorded in this page.

## Evidence

- PR #34 squash merge `9db01952` and release tag `v3.1.0`.

## Known limitations and follow-up

The first deployment tool packaged one app at a time. Multi-app bundles were
added later. The changelog model introduced here was subsequently replaced by
component-linked history pages generated with the documentation site.
