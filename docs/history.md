# Project History

LabKit keeps change explanations with the documentation area they affect.
Framework, library, app, launcher, and project records are separate Markdown
pages rather than sections in one repository-wide changelog.

The generated list below is assembled from those pages. A cross-component
change is written once and appears automatically on every related component
page. Current versions come directly from launcher, facade, and app
`version.m` metadata rather than a duplicated lookup table.

## Reading A Record

Each record identifies its date, change type, compatibility effect, affected
components, rationale, behavior or data impact, validation, evidence, and known
follow-up. Search by component command, public facade, Change ID, or scientific
term to locate a decision.

## Maintaining History

Add one Markdown record under the relevant `history/` directory when a
versioned component or meaningful repository behavior changes. Do not edit
generated HTML. Rebuild the site so the record appears in global search and on
every matching component page.

