# Debug workflows, launcher tools, and changelog governance

```labkit-change
schema: 1
id: LK-20260707-debug-workflows-launcher-tools-and-changelog-governance
date: 2026-07-07
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
```

## Context

- The debug sample workflows can be exercised without false crash reports or
  disabled-looking app paths when the required user action is folder loading,
  ROI anchor completion, or crop-center confirmation.
- Code Analyzer cleanup can be reviewed from an interactive local HTML report
  without making the launcher own a growing maintenance workflow.
- A single lab workflow can be distributed into a fixed production or offline
  deployment step without shipping unrelated apps, tests, docs, or repository
  metadata.
- Developers can keep private LabKit apps next to a public checkout, use the
  ordinary launcher to open them, and push that workspace to a separate private
  repository.
- Maintainers and agents can understand project direction from the changelog
  without reconstructing intent from raw git history.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

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

- The debug sample workflows can be exercised without false crash reports or
  disabled-looking app paths when the required user action is folder loading,
  ROI anchor completion, or crop-center confirmation.
- Code Analyzer cleanup can be reviewed from an interactive local HTML report
  without making the launcher own a growing maintenance workflow.
- A single lab workflow can be distributed into a fixed production or offline
  deployment step without shipping unrelated apps, tests, docs, or repository
  metadata.
- Developers can keep private LabKit apps next to a public checkout, use the
  ordinary launcher to open them, and push that workspace to a separate private
  repository.
- Maintainers and agents can understand project direction from the changelog
  without reconstructing intent from raw git history.

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

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- PR #34 squash merge and release tag `v3.1.0`.

## Known limitations and follow-up

- Keep debug fixes moving into shared callback and editor contracts when the
  failure pattern is reusable, but keep app-specific workflow decisions in the
  owning app.
- Keep changelog entries organized around evolution themes and release lines,
  not raw tag rows or issue lists.
