# Launcher separates shared discovery and published-Release workflows

```labkit-change
id: LK-20260819-launcher-release-boundary
date: 2026-08-19
sequence: 184
type: refactor
compatibility: breaking
component: `labkit_launcher` | `1.8.4 -> 2.0.0`
scope: Launcher controller and native view ownership
scope: Shared App discovery and invocation ownership
scope: Published GitHub Release installation
scope: Source-only App deployment packages
scope: Figure Studio plot handoff
```

## Context

The Launcher window combined native layout, mutable state, App discovery, dynamic invocation, maintainer-tool adaptation, version-source discovery, packaging variants, and an App-specific Figure Studio callback in one implementation. Documentation generation queried the public Launcher entry again, creating a circular dependency through the Launcher dispatcher. Version controls also exposed overlapping main-branch, latest-release, and mixed release/tag/commit choices, while the deployment tool maintained a second P-code product shape.

## Decision and rationale

Keep the Launcher as the visible App catalog and command surface while giving each dependency boundary one focused owner. A GUI-free private discovery boundary owns App descriptors, scanning, path activation, and revalidated invocation for the Launcher, documentation catalog, and plot-to-App handoffs. The native view owns handles and responsive layout, the controller owns state and callbacks, and fixed adapters own maintainer tools. Version installation accepts only published stable GitHub Releases. Deployment packages contain MATLAB source only. Plot-to-Studio handoff belongs to the popout plot capability and must not require a Launcher window or global callback.

## Changes

- Split Launcher view construction, controller state, App catalog projection, tool availability, and tool invocation into focused internal owners; moved App scanning, path activation, and discovered-App invocation to the shared private discovery boundary.
- Removed the documentation-to-public-Launcher call that completed the Launcher dependency cycle.
- Removed the global `labkitFigureStudioLauncher` callback and direct Launcher-to-Figure-Studio dependency; **Send to Studio** now discovers and invokes the installed Studio App from the plot boundary.
- Reduced the visible version controls to **Latest** and **Versions**. Both use published stable GitHub Releases; Versions shows release date and release information.
- Removed main-branch, raw tag, and commit version sources from installation workflows.
- Removed P-code discovery, packaging, manifest fields, documentation, controls, and compatibility behavior. App packages now contain MATLAB source only.
- Preserved App discovery, private-App roots, two-stage startup feedback, busy-state restoration, online App documentation, source-checkout maintenance actions, multi-App selection, and the existing responsive visual design apart from the deliberately removed controls.

## User and data impact

Users see two version actions instead of three and one package action instead of two. **Latest** installs the latest published stable Release. **Versions** lists published stable Releases and their information before installation. Existing source packages and App commands continue to work; no scientific data, project file, result, or App workflow changes.

## Compatibility and migration

P-code packages and main/tag/commit installation choices are intentionally retired without compatibility aliases. Maintainer automation that called `manageLabKitVersions(..., "stable")` must use `"latest"`. The public `labkit_launcher` GUI, `list`, `version`, and `documentation` entry modes remain available; the Launcher component advances to 2.0.0 for the deliberate capability removal.

## Validation

Focused Launcher, standalone repair, version-management, App SDK plot, deployment, and repository architecture specifications cover the new ownership and Release-only contracts. A MATLAB-exported post-change Launcher image is compared with the pre-change baseline to verify that only the requested controls changed.

## Evidence

Static dependency guards prohibit Launcher ownership of Figure Studio, require plot handoffs to use the shared discovery boundary, and prohibit documentation from re-entering `labkit_launcher`. Dynamic invocation remains limited to a discovered `labkit_*_app.m` entry revalidated against its owning folder. Source searches verify that production and current manuals no longer contain P-code behavior.

## Known limitations and follow-up

Automated hidden GUI checks do not prove native rendering at every display scale. The maintained MATLAB API screenshots provide the manual visual comparison boundary for this redesign.
