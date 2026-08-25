# Reader-centered documentation and unified change rationale

```labkit-change
id: CHG-20260825-reader-centered-documentation
date: 2026-08-25
type: docs
compatibility: breaking
component: documentation
supersedes: CHG-20260715-documentation-site
supersedes: CHG-20260715-component-owned-history
supersedes: CHG-20260716-history-adjacent-navigation
supersedes: CHG-20260719-path-derived-documentation
supersedes: CHG-20260721-canonical-history-record-format
supersedes: CHG-20260806-retired-documentation-history-links
```

## Why

The generated site exposed repository structure more clearly than it guided a new user, App user, developer, or maintainer toward an outcome. Public package coverage could be incomplete, long error identifiers could overlap their descriptions, and readers had to infer which documentation path applied to them. The history schema preserved delivery evidence but made a simple human question—what changed and why—expensive to answer.

The accepted choice is a hard cutover to reader- and intent-based pages, typed metadata, generated public coverage, and one lightweight Change record that owns both the accepted change and its rationale. A separate decision record was considered and rejected because it splits one reader question across two records and creates another classification rule for maintainers.

## What changed

Current pages gained explicit semantic ID, type, audience, and summary metadata; current authority is implied and App or package ownership is derived instead of repeated. The reference chooser now includes `labkit.mark10`, and definition lists keep long MATLAB errors inside responsive cells. Navigation is organized by reader destination, while each App keeps one complete manual unless a child topic can stand independently. Changes use one typed header and generated relationships, while GitHub Releases remain the sole published-version summary. A newer Change may name earlier Changes with `supersedes`; no independent Decision type, directory, navigation area, or renderer remains. CSS and JavaScript are ordinary source assets, and Markdown prose uses one physical line per paragraph with automated validation.

## Impact

Readers can enter by goal, distinguish current instructions from evolution, and follow both directions of a replacement chain without reading Git or pull requests. Authors have one four-section format for meaningful changes and one release summary format. Agent rules, the documentation Skill, renderer, and integration policy share the same ownership model so future edits do not silently restore parallel histories.

## Compatibility and limits

The documentation URL structure is intentionally breaking: moved or retired pages receive no redirects, aliases, or archived copies. Historical Change text can explain an earlier structure, but it does not keep an earlier route alive. App calculations, project data, exports, and MATLAB public behavior do not change.
