# 2.1: RHS apps and shared runtime stability

```labkit-change
id: LK-20260621-v2-1-rhs-and-runtime-stability
date: 2026-06-21
sequence: 7
type: feat
compatibility: compatible
scope: historical project evolution
```

## Context

After v2.0, the UI runtime supported several app families but still repeated
important behavior around busy actions, path events, preview zoom, and layout
ownership. A new neurophysiology family would amplify those inconsistencies if
each app solved them independently.

## Decision and rationale

Add RHS reading and review as a first-class app family while centralizing only
the runtime mechanics shared across domains. Filtering choices and response
analysis remained in the RHS workflows; transactions, path events, zoom, and
layout ownership belonged to the UI layer.

## Changes

- Added RHS Preview, Nerve Response Analysis, and Response Review Stats.
- Folded the separate screening step into preview filtering so file review used
  one workflow rather than two overlapping stages.
- Added duplicate Batch Crop tasks for repeated crop layouts.
- Unified preview scroll zoom and centralized action busy transactions.
- Centralized path-event contracts and app layout ownership.
- Added a ZIP-based updater and stabilized image and app interactions before
  release.
- Reduced focused test discovery and guardrail cost as the repository grew.

## User and data impact

Neurophysiology users gained file preview, response analysis, and review
statistics apps. Existing users saw more consistent zoom, busy feedback, path
updates, and responsive layout behavior. The updater provided a repository-
owned way to install a packaged release.

## Compatibility and migration

The RHS family was additive. UI implementations that maintained their own
copies of busy, path, or layout mechanics were migrated to the shared runtime
contracts.

## Validation

The stage added RHS-focused tests, interaction regressions, compatibility input
checks, path-event checks, and faster focused test routing. Tag `2.1` points to
`76ddf7d0`.

## Evidence

- RHS app family `7ddc036f` and preview filtering `ca8a37dd`.
- Shared interaction mechanics `eb52eb17`, `f3e42b8e`, `1fe89ba2`.
- Layout ownership `3ce4c8f7`, `09baf7fe`.
- Updater `e4b02f3a`.
- 2.1 release stabilization `76ddf7d0`.

## Known limitations and follow-up

The updater still depended on how the launcher was installed, and several
image workflows reset zoom or recomputed previews during edits. The following
2.2 and 2.3 releases concentrated on self-contained launch and direct image
manipulation.
