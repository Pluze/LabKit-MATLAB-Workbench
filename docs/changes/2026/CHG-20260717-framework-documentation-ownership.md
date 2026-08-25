# Framework owns UI and compatibility documentation

```labkit-change
id: CHG-20260717-framework-documentation-ownership
date: 2026-07-17
type: docs
compatibility: compatible
component: repository
```

## Why

The documentation described `labkit.ui` as the App Framework but presented its public API and the compatibility contracts through the generic Functions area. The visible information architecture therefore disagreed with the framework terminology used by app development guides.

### Accepted choice

Make Framework the documentation owner for `labkit.ui.*` and `labkit.contract.*`. Compatibility requirements belong in the Framework because App definitions and startup consume them. Keep the stable `labkit.contract` MATLAB namespace because it checks UI and domain facades alike; moving it below `labkit.ui` would create a misleading dependency and break existing App definitions.

## What changed

- Added compatibility contracts as a Framework sidebar branch.
- Classified UI and contract API pages under the Framework top navigation.
- Replaced raw UI package headings with visible Framework API labels while retaining fully qualified MATLAB symbols.
- Removed the separate Contracts entry from the Functions guide table.

## Impact

Readers now enter framework runtime, layout, plotting, interaction, debugging, and compatibility material through one consistent Framework route. MATLAB calls, saved projects, scientific results, and URLs remain compatible.

## Compatibility and limits

No code migration is required. Existing `labkit.ui.*` and `labkit.contract.*` symbols are unchanged.

### Remaining limits

The global API reference still indexes all public symbols together so exact MATLAB functions remain searchable from one place.
