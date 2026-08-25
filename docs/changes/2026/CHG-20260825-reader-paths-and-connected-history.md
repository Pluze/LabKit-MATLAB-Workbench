# Intent-based reader paths and connected change history

```labkit-change
id: CHG-20260825-reader-paths-and-connected-history
date: 2026-08-25
type: docs
compatibility: breaking
component: documentation
component: labkit_launcher | 2.0.0 -> 2.0.1
supersedes: CHG-20260825-reader-centered-documentation
supersedes: CHG-20260717-hierarchical-documentation-navigation
```

## Why

The first reader-centered cutover improved page ownership but still mixed three classification axes at the top level: reader roles in Start and Apps, repository duties in Develop and Maintain, and content modes in Reference and Changes. Real tasks crossed those boundaries immediately—for example, App development sent the same reader to a separate maintenance tree for testing—and every Change still appeared in one sidebar. The accepted choice uses one top-level axis: reading intent. Use owns running LabKit and App manuals, Develop owns the complete source lifecycle, Reference owns exact lookup, and Changes owns accepted rationale. A separate maintainer tree, a separate App top level, a hand-maintained site map, and additional decision record types were rejected because they fragment one journey or duplicate relationships the renderer can derive.

## What changed

The site now presents Use, Develop, Reference, and Changes. Installation, version selection, Launcher help, the App catalog, and App manuals form one Use tree. App authoring, framework and library guidance, data design, private Apps, testing, documentation, source tools, and release form one Develop tree. The former Start, Apps, Maintain, and Upgrade routes were removed. Every page gains generated breadcrumbs, bounded section navigation, a responsive page outline, and a footer route to a generated documentation map. Changes can be browsed by recent acceptance, component, year, and compatibility without entering a complete-record sidebar; individual records link to component archives, current guides, and supersession chains. App guides and API pages show recent related Changes. The Launcher button is now **Open App Guide**, and both Launcher and renderer use the same canonical `use/apps/<family>/<app>/` route. Error identifiers break only at semantic delimiters or scroll within their term column instead of colliding with descriptions.

## Impact

New users remain in one Use journey from installation to the relevant App manual. Developers remain in one Develop journey through implementation, validation, documentation, and delivery, switching to Reference only for exact contracts or Changes only for historical rationale. Maintainers can trace a decision without reconstructing Git or losing the route back to present behavior. Navigation, maps, archives, relationships, and search stay synchronized as new Apps, functions, and Changes are discovered. Agent guidance records the same invariants so later edits do not recreate role-based top-level splits, flat global lists, or duplicate catalogs.

## Compatibility and limits

The documentation route change is intentional and receives no redirect or alias. Existing bookmarks under the former `start/`, `apps/`, `maintain/`, and top-level `upgrade/` routes stop working; use the new intent landing pages and canonical trailing-slash App routes under `use/apps/`. The Launcher change is compatible with App execution and raises its component version from 2.0.0 to 2.0.1. Generated component links are exact when current metadata identifies an owner; retired components can retain a historical archive without pretending that an obsolete manual is current.
