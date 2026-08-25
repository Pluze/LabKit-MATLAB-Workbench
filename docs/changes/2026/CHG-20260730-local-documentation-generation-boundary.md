# Local documentation generation boundary

```labkit-change
id: CHG-20260730-local-documentation-generation-boundary
date: 2026-07-30
type: fix
compatibility: compatible
component: labkit_launcher | 1.8.0 -> 1.8.1
```

## Why

The first online-first documentation delivery made the Launcher maintenance button open an existing local page or synchronously ask whether to generate, open online, or cancel when that page was absent. The confirmation call used a return value, which blocks MATLAB execution. On affected desktop versions the callback could remain at **Opening local documentation** without restoring the Launcher controls.

### Accepted choice

Keep documentation reading and documentation generation as separate actions. **Documentation and History** owns online reading. **Generate Local Documentation** owns one deterministic maintenance operation: rebuild the complete ignored `site/` folder from current authored sources. It does not open a browser or display a source-choice dialog.

This smaller boundary removes the blocking confirmation path, avoids overlap between two Launcher buttons, and guarantees that selecting local generation always refreshes stale output rather than merely opening it.

## What changed

- Renamed the maintenance action to **Generate Local Documentation**.
- Made every activation call the repository documentation renderer for the complete `docs/` to `site/` build.
- Removed local-page opening and online/local/cancel prompting from that maintenance callback.
- Kept the programmatic explicit `"local"` documentation lookup for callers that need an already-generated filesystem path.

## Impact

The maintenance button now consistently generates current local help and then restores the Launcher controls. Online help remains the default reading path. No App project, input, result, export, or scientific behavior changes.

## Compatibility and limits

The change is compatible with existing Launcher startup and online documentation behavior. Users who want local reading generate the site first, then open the returned programmatic local path or browse the `site/` folder.

### Remaining limits

Automated hidden-GUI checks do not measure documentation rendering time or prove native browser behavior. The generation action intentionally remains synchronous so its completion status cannot precede the finished local site.
