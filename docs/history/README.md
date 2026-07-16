# Project History

This page lists the recorded changes to LabKit in reverse chronological order.
Each change has its own page, so a reader can open the reason, effect,
compatibility notes, and validation without searching through one very long
changelog.

## How LabKit Took Shape

The early records are more than release notes. They explain how imported
laboratory scripts became an app workbench and why the current boundaries exist.

### Before v1.0

1. [Legacy import and first app workbench](records/2026/05/LK-20260528-initial-app-workbench-foundation.md)
   follows the first separation of parsers, calculations, exports, and app
   entry points.
2. [DTA facade and app ownership boundaries](records/2026/05/LK-20260529-dta-facade-and-app-boundaries.md)
   explains why reusable file operations moved into a library while workflow
   decisions stayed with their apps.
3. [LabKit name and the first multi-domain app families](records/2026/05/LK-20260530-app-family-expansion.md)
   covers the move beyond electrochem into DIC, curvature, and biosignals.
4. [Managed image interactions and diagnostic tracing](records/2026/06/LK-20260604-managed-image-interactions.md)
   records the first framework response to reentry, ownership, zoom, and
   callback-diagnostic problems.
5. [v1.0: app-owned packages and a standard test platform](records/2026/06/LK-20260606-v1-foundation.md)
   describes the release baseline rather than treating the tag as the start of
   the project.

### The 2.x Line

1. [v2.0: launcher, image apps, and UI 2.0](records/2026/06/LK-20260615-v2-launcher-and-ui2.md)
   introduced the visible launcher and the second UI contract.
2. [2.1: RHS apps and shared runtime stability](records/2026/06/LK-20260621-v2-1-rhs-and-runtime-stability.md)
   added neurophysiology workflows while centralizing busy, path, zoom, and
   layout mechanics.
3. [v2.2 to v2.3.1: self-contained launch and image workflow refinement](records/2026/06/LK-20260621-v2-2-v2-3-image-workflows.md)
   follows the updater, multi-file selection, crop scaling, and zoom-preserving
   editing work.
4. [v2.3.2 and v2.3.3: preview performance and release contracts](records/2026/06/LK-20260623-v2-3-performance-and-release-contracts.md)
   explains the preview/export boundary and the move to reproducible release
   assets.

Later records continue the same format and attach changes to the components
they affected. The complete reverse-chronological list appears below in the
rendered site.

History source files have one predictable home:

```text
docs/history/records/<year>/<month>/
```

The folder is chronological, while the metadata inside each record names the
apps, framework, or libraries affected by the change. The documentation site
uses that metadata to show a relevant **Change history** section on each
component page. A change that affects several components is stored once and
linked from all of them.

## Find A Change

Use the site search for an app command, public function, Change ID, or feature
name. You can also browse the complete list below by date. Current version
numbers come from the launcher and component `version.m` files rather than from
a separate table in this history.

## Add A Record

Create one Markdown file in the folder for its year and month. Include the
date, change type, compatibility, affected components, reason for the change,
user or data effect, validation, evidence, and any known limitations. Rebuild
the documentation after editing the source; generated HTML is never edited by
hand.
