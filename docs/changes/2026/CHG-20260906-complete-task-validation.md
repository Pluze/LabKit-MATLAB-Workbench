# Complete task validation and executable Skill routes

```labkit-change
id: CHG-20260906-complete-task-validation
date: 2026-09-06
type: fix
compatibility: compatible
component: repository
```

## Why

A final local test plan must account for the complete task, including earlier commits and deleted source. Selecting only uncommitted edits or the last checkpoint could omit affected owners while still producing a passing focused result. Agent workflow routes also need structural validation so an incomplete or renamed Skill cannot silently disappear from the checked contract.

## What changed

Local changed-path planning uses the task's merge base with fetched `origin/main` and includes working-tree changes. Deleted paths and both sides of renames retain their ownership obligations in local and hosted focused feedback. Without a task delta, local edits or the last clean checkpoint remain the available fallback. Skill validation rejects missing entry points and unresolved backticked repository Skill routes, and missing literal documentation targets. App construction guidance follows optional state and continuation needs, and state callback guidance matches the SDK signatures and App-owned posted continuations while keeping calculation helpers narrow.

## Impact

Maintainers receive evidence selection for the whole proposed task rather than only its latest editing layer. Source deletion can expose missing ownership that was previously omitted from the plan. Native presentation regression evidence checks restoration after a renderer has already changed a plot, including a subsequent successful state transition.

## Compatibility and limits

Product APIs, numerical results, App interfaces, and saved data are unchanged. Fetch the main reference before final local validation. Retiring a complete evidence owner requires an explicit consumer and retirement review when no surviving contract can be selected. Focused tests remain local feedback; required CI owns platform coverage. Skill checks validate structure and references, not a model's activation accuracy or compliance.
