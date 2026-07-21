# Project History

This page lists the recorded changes to LabKit in reverse chronological order.
Each change has its own page, so a reader can open the reason, effect,
compatibility notes, and validation without searching through one very long
changelog.

## Reading The Timeline

Every recorded change, including work before v1.0, appears once in the same
reverse-chronological timeline below. Early records describe how imported
laboratory scripts became an app workbench; later records use the same page
format to explain framework, library, App, validation, and release decisions.
Version boundaries are milestones in this one timeline, not separate kinds of
history.

History source files have one predictable home:

```text
docs/history/records/<year>/<month>/
```

The folder is chronological, while the metadata inside each record names the
apps, framework, or libraries affected by the change. Every record also has a
global positive-integer `sequence`. Sequence values are unique and contiguous:
the first record is `1`, and each later change takes the next value even when
several changes share a date. The generated timeline sorts by descending
sequence, so titles and filenames cannot reorder same-day versions. Dates must
remain nondecreasing as sequence increases. The authoritative
[history record format](record-format.md) defines every metadata field and
body section.

The documentation site uses that metadata to show a relevant **Change
history** section on each component page. A change that affects several
components is stored once and linked from all of them.

## Find A Change

Use the site search for an app command, public function, Change ID, or feature
name. You can also browse the complete timeline below by date. Current version
numbers come from the launcher, facade `version.m` files, and App
`definition.m` metadata rather than from a separate table in this history.
