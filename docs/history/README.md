# Project History

This page lists the recorded changes to LabKit in reverse chronological order.
Each change has its own page, so a reader can open the reason, effect,
compatibility notes, and validation without searching through one very long
changelog.

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
