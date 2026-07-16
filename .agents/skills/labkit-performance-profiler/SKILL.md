---
name: labkit-performance-profiler
description: Use when diagnosing LabKit MATLAB performance, launcher cold-start cost, startup or callback profile reports, profileLabKitTarget runs, AGENT_SUMMARY extraction, or source-tagged profile optimization work.
---

# LabKit Performance Profiler

Use this skill for LabKit performance work where MATLAB profiler output is the
primary evidence. Keep changes scoped to the slow path that the profile proves.

## Read First

1. Read `AGENTS.md`.
2. Read the source or test files directly involved in the measured target.
3. Read `docs/development/testing.md` for the current profiling command and validation
   route.

For package-boundary changes, also use `labkit-boundary-guard`. For validation
planning, also use `labkit-test-planner`.

## Fresh Profile Run

For agent-friendly launcher profiling from a source checkout:

```bash
matlab -batch "addpath(fullfile('tools','profiling')); profileLabKitTarget('labkit_launcher', [], 'OpenReport', false, 'WaitForGuiClose', false, 'CloseFiguresAfterRun', true, 'PrintSummary', true)"
```

The batch entry point prints and writes:

- `profile_*.html`
- `profile_*.json`

Use escalated sandbox permissions for MATLAB runs when required by the repo
instructions.

## Source Tags

Profiler rows are not dropped. The tool tags each row instead:

- `project`: file is inside this checkout.
- `matlab_internal`: file is under `matlabroot`.
- `external`: file is outside this checkout and outside `matlabroot`.
- `profiler_tool`: profiler implementation row.

Use `source_tag` and `tags` for grep or agent-side filtering. Keep the full JSON
as raw evidence when comparing profile runs.

## Reading Reports

Start with the JSON sidecar's `summaryText` or the `AGENT_SUMMARY_BEGIN` block
embedded in the HTML. If exact row data is needed, read the JSON sidecar's
`functions` array. If parent or child edges matter, inspect those row fields or
extract the embedded `profile-json` from the HTML.

Interpret tables this way:

- `top_project_self_time`: first table for editable LabKit code.
- `top_captured_self_time`: useful for seeing whether non-LabKit rows still dominate.
- `top_captured_total_time`: workflow context. It may include deliberate clicks, app
  launches, network calls, or time spent waiting for GUI close.

Check `source_tag` and `tags` before drawing conclusions from rankings.

Keep measured scenarios narrow:

- Startup targets should open the launcher or app, call `drawnow`, pause only
  long enough for initial UI work to settle, and rely on `CloseFiguresAfterRun`
  for cleanup. Profile close latency as a separate scenario.
- Compare normal and debug launches separately. Debug trace mirroring is a real
  developer workflow cost, but it should not be reported as ordinary user
  startup cost.
- For large-file UX complaints, profile the chooser callback path separately
  from Run or Export. Use synthetic multi-file inputs and compare path-only
  registration with app-owned readers before changing algorithms.
- Treat single GUI runs as directional. MATLAB web UI creation and event
  scheduling can create outliers, so confirm shared-framework changes with
  representative runs plus focused tests.

## Optimization Workflow

1. State the measured scenario and profile artifact path.
2. Identify the narrow slow path from agent summary rows and, when needed,
   parent/child edges.
3. Change the owning source only; do not move profiler helpers into public
   `+labkit` facades.
4. Add or update focused tests for changed behavior or guardrails.
5. Run validation using the changed-file route in `docs/development/testing.md`.
6. Handoff the profile evidence, changed files, validation result, and any
   unverified interactive GUI behavior.
