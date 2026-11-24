---
name: labkit-test-planner
description: "Select, run, review, or repair LabKit validation; design missing tests, fixtures, and CI coverage. Existing evidence is reused. Documentation-only checks stay with documentation maintenance."
---

# LabKit Test Planner

Start with the requested source, specification, failed identity, or evidence
question. Read applicable rules and relevant sections of
`docs/develop/testing.md`; read catalog implementation only when diagnosing or
changing the catalog. Preserve the caller's mode: a review inspects evidence
without creating tests, and a run request executes existing selected tests.

## Resolve and run evidence

For changed source, use `labkittest.explain(SOURCE_FILE)` to resolve ownership
and the bounded evidence closure. When the failed identity is already known,
pass it unchanged to `labkittest.run(Id=IDENTITY)`, including any parameter
suffix. Reuse existing specs;
add or extend tests only for a relevant gap in the requested contract. Use
`labkittest.createSpec` only when a new specification is needed, with a
Regression, Invariant, or Compatibility reason.

Run by exact identity, owner/contract, or the known source-file closure. A
missing contract, unknown identity, or zero selection requires diagnosis.
Require persistence evidence only for an affected App-owned continuation
contract, not from a filename alone.

For test design, fixtures, or App GUI coverage, read
[evidence design](references/evidence.md) and `tests/AGENTS.md`. For CI scope,
feedback, or repair, read [CI procedure](references/ci.md). Supporting review
uses the relevant criteria without running authoring steps.

## Complete the requested check

Use host permissions for MATLAB and bounded noninteractive processes. Native
hidden-GUI evidence does not prove dialogs, pointer feel, visual quality,
real-data suitability, or scientific validity; report those limits when relevant.

Run `changedFast` at final pre-PR preparation, not ordinary iteration. Reuse
valid checks and broaden or repeat only when changed scope, failures, or
unresolved concerns justify it. An explicit full-suite request is in scope;
confirm the intended profile from context and execute it without adding tests.

Report the exact selection/command, count, result, artifact, and relevant
manual gaps. A planning-only task finishes with a justified plan; execution
finishes with results or a diagnosed blocker; authoring also requires evidence
that the new assertion detects a plausible production defect.
