# Local validation uses one focused route and CI owns full coverage

```labkit-change
id: CHG-20260721-local-validation-routing
date: 2026-07-21
type: test
compatibility: compatible
component: repository
```

## Why

The repository exposed both `changedFast` and a conservative `changed` task. For documentation, agent guidance, and CI workflow changes they selected the same complete project suite, so running both locally duplicated work that the cross-platform CI already repeated more comprehensively.

### Accepted choice

Keep one local changed-file task, `changedFast`, for a focused pre-push check. PR and main-push CI remain the complete validation gate because they run the full headless and hidden-GUI suites on every supported platform.

## What changed

Removed the public conservative `changed` task and its runner entry. Guidance, templates, workflows, and CI helpers now route to their owning documentation or CI guardrails instead of the complete project suite. Broad GUI candidate selection remains reduced to representative workflows for the local route.

## Impact

App behavior, saved projects, analysis results, and laboratory data do not change. Contributors receive faster local feedback while the same complete platform coverage remains mandatory before delivery.

## Compatibility and limits

Use `buildtool changedFast` for the local pre-push checkpoint. The retired `buildtool changed` command is intentionally unavailable; use CI results for complete validation rather than substituting another local broad run.

### Remaining limits

Local `changedFast` is intentionally not a substitute for CI or manual App review. If a new shared surface lacks an owning test route, add that route rather than broadening unrelated local checks.
