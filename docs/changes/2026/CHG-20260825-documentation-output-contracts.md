# Documentation output contracts and maintenance lifecycle

```labkit-change
id: CHG-20260825-documentation-output-contracts
date: 2026-08-25
type: fix
compatibility: compatible
component: documentation
```

## Why

The documentation compiler validated source metadata, local link targets, and reproducible bytes, but those checks could reproduce and publish the same incomplete page twice. The Reference landing promised generated module tables while a stale coordinator condition prevented the catalog from running; several public image functions consequently had no direct current-guide entry, and two API pages contained duplicate heading IDs. API and Change supplements were also activated through parallel single-purpose renderer files, so page semantics were spread between the compiler coordinator and feature implementations. Future source-change guidance said to update documentation but did not require an explicit create, update, retire, or verified-no-change decision.

## What changed

The Reference catalog now derives every module, guide, function row, and function-page link from the normalized API model, including Mark-10 and App-owned GUI-free APIs. Package guides use package ownership instead of incidental symbol mentions. API catalogs and Change supplements each have one semantic renderer owner, while the compiler coordinator only sequences model loading, rendering, generated indexes, assets, search, whole-site validation, and synchronization. The new output gate rejects missing pages, duplicate IDs, invalid landmarks or heading order, empty tables, broken links or fragments, unreachable pages, incomplete search/map/API coverage, and public APIs without a current narrative entry point before output is synchronized. Duplicate help headings were consolidated without removing their examples. Repository rules and the documentation Skill now require every affected reader or public surface to be classified as documentation creation, update, retirement, or a verified no-current-doc change, with activation cases for each lifecycle boundary.

## Impact

Readers can follow the Reference overview from a module guide to every supported public function instead of encountering a promise followed by an empty page. The page outline remains bounded because module groups sit below the single Browse By Module entry. Documentation authors and agents get one source-derived discovery path and a publishing failure when a page is structurally present but semantically incomplete. Future App, API, schema, workflow, and compatibility changes have an explicit documentation-completeness decision before integration, while verified internal refactors avoid unnecessary reader-facing churn.

## Compatibility and limits

Current authored documentation routes, MATLAB public behavior, App workflows, calculations, files, and data formats are unchanged. No redirect, legacy alias, or archived route is added. The validator proves generated structure, reachability, and model coverage; representative visual inspection is still required when CSS, responsive layout, or browser interaction changes.
