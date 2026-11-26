---
name: labkit-documentation-maintainer
description: "Maintain LabKit manuals, public MATLAB help, documentation discovery/rendering, structured Change records, and Release notes or publication. Source-only fixes with unchanged reader contracts stay with their source owner."
---

# LabKit Documentation Maintainer

Read applicable rules, including `docs/AGENTS.md`, and affected reader sources.
Inspect source/tests needed to establish each changed claim. Read
`docs/develop/documentation.md` for tooling or discovery changes, and
`docs/develop/release.md` plus [release procedure](references/releases.md) only
for release work. Do not load publication mechanics for ordinary page edits.

## Maintain the affected reader contract

Classify the accepted change as create, update, retire, or no current-doc change
using `docs/AGENTS.md`. For an App contract, inspect its definition, affected
help/manual, labels, and relevant tests; for a facade contract, inspect the
changed public help, consumers, owning guide, and generated discovery. Expand
that inspection only when shared discovery or a broader contract changes.

For user guides, name the control the reader will see, the action to take,
and the result to look for. Use the current UI label and keep units and
scientific qualifiers that affect interpretation. Remove phrases that only
describe how the documentation is organized when they do not help readers
choose their next step.

Write at the current fact owner. For moves or retirement, update live links and
catalog ownership and remove obsolete routes. For new public surfaces, verify
the reader can reach the help from the owning catalog and return to the guide.
Use one structured Change when accepted rationale, impact, or compatibility
needs a durable explanation; keep validation inventories in the PR.

Use `labkit-boundary-guard` only when an actual public or ownership decision is
needed, and `labkit-agent-governance` when agent instructions change.

## Verify and finish

For authored page/help, documentation-rule, or renderer changes, run the smallest
relevant check and `buildtool docsCheck`, reusing the final gate when it includes
that check. Inspect representative desktop/mobile output when layout,
navigation, tables, search, or interaction changes. A read-only audit inspects
available evidence and reports gaps without modifying the documentation.

For external release-only edits, normalize and read back the published record
and audit its tag-to-tag coverage; no local docs run is needed unless repository
documentation also changes. For deployment, use the existing documentation
workflow and verify the requested commit and published result.

Report changed reader owners, verified no-doc conclusions, relevant checks,
visual/manual gaps, and the requested publication or deployment state.
