# Real workflows are independent App evidence

```labkit-change
id: CHG-20260827-real-workflow-test-evidence
date: 2026-08-27
type: fix
compatibility: compatible
component: labkit.app | 3.2.0 -> 3.2.1
component: labkit_BatchImageCrop_app | 1.10.2 -> 1.10.3
component: labkit_Mark10Monitor_app | 1.1.0 -> 1.1.1
```

## Why

The catalog had many direct calculation, state, export, and presentation specifications, but an App could still lack one native source-to-result journey. Batch Image Crop demonstrated the gap: focused tests supplied a test-only item shape and never selected a production PNG, so preview and export failures remained invisible until manual use.

### Accepted choice

Keep narrow owner tests and add `workflow` as independent evidence rather than replacing the test pyramid with end-to-end tests. Require every App to own a hidden native core journey through its real source boundary, inventory custom GUI interactions separately, and measure headless and workflow coverage as distinct omission metrics. Treat coverage and interaction matching as diagnostics; they do not turn assertion-free execution into passing behavior evidence.

Making line coverage a universal completeness score was rejected because it cannot establish scientific correctness, callback outcomes, or reachable workflow order. Generating every possible GUI action combination was rejected because it would create an unreviewable Cartesian suite while still missing independent scientific oracles.

## What changed

- Added native core-journey catalog and build profiles, separate headless and journey coverage reports, App interaction omission reporting, and CI coverage artifacts.
- Added missing production workflows for Batch Crop, Image Enhance, T-Test Wizard, and Mark-10 Monitor, and reclassified the existing App workflows by their actual evidence semantics.
- Repaired Batch Crop preview identity, incomplete-task error reporting, and pixel-manifest restoration after the real PNG journey exposed those failures; compatible pixel manifests without dormant physical dimensions derive them from their positive pixel crop size.
- Cleared recovered Mark-10 settings failures and made the native workflow prove connection failure, synthetic device reads and zeroing, monitoring export, replay, modulus analysis, and result export.
- Allowed figure annotations to create a rectangle from the current axes domain when no image-size contract exists, which restores annotation editing for ordinary plotted figures without changing image-backed ROI defaults.
- Added semantic target and operation kind to native presentation failures while retaining the original cause.
- Updated test and App authoring policy so fixtures cannot define their own oracle and every new behavior test must identify a plausible counterfactual it detects.

## Impact

Maintainers can run all core App journeys directly, review coverage by evidence population, and identify declared interactions without owning evidence. Batch Crop users can preview normal selected images, receive actionable incomplete-task messages, and restore pixel manifests without invalid numeric controls.

## Compatibility and limits

Scientific formulas, supported input formats, output schemas, and saved manifest columns are unchanged. Hidden GUI automation does not prove operating-system dialogs, pointer feel, visual design, real-data suitability, or scientific interpretation; those remain explicit manual acceptance boundaries.
