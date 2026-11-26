# API Reference

```labkit-page
id: reference
type: landing
audience: app-developer
summary: Find exact contracts for LabKit domain libraries and GUI-free App APIs, including biosignal, DTA, image, Mark-10, NI-DMM, RHS, and thermal functions.
```

This index covers domain libraries and GUI-free App APIs. The App SDK itself is documented under [Framework: App SDK API](../develop/framework/app-sdk-api.md), so its contracts stay with the lifecycle and architecture guidance they support.

Each module below links to its guide and function pages. Use the guide for a workflow and the function page for syntax, defaults, outputs, and errors. Examples marked `Example:` run in `docsCheck`. A `Typical Call:` may need your own file or device.

## Compatibility

Each reusable library publishes a `version()` result. Apps declare compatible library ranges in the `Requirements` field of their single `definition.m` contract. A function documented here is public within that library version; compatibility across a breaking version is not implied.

The tables below are generated from current MATLAB source. Each entry links to the current function help.
