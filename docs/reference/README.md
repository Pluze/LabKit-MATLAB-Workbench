# API Reference

```labkit-page
id: reference
type: landing
audience: app-developer
summary: Find exact contracts for LabKit domain libraries and GUI-free App APIs, including biosignal, DTA, image, Mark-10, RHS, and thermal functions.
```

This index covers domain libraries and GUI-free App APIs. The App SDK itself is documented under [Framework: App SDK API](../develop/framework/app-sdk-api.md), so its contracts stay with the lifecycle and architecture guidance they support.

Use this reference to look up supported MATLAB functions. Every function name in the generated module tables is a direct link to an individual page with syntax, arguments, outputs, behavior, source, and related APIs.

## Find The Right Layer

| Need | Module guide |
| --- | --- |
| App lifecycle, layout, plotting, interaction, state, debugging, and compatibility requirements | [App Framework](../develop/framework/README.md) |
| Image IO and generic image operations | [Image](../develop/libraries/image/README.md) |
| Radiometric image decoding and temperature conversion | [Thermal](../develop/libraries/thermal/README.md) |
| Gamry DTA discovery, parsing, curves, and pulses | [DTA](../develop/libraries/dta/README.md) |
| Intan RHS inspection and waveform windows | [RHS](../develop/libraries/rhs/README.md) |
| Generic biosignal import and processing | [Biosignal](../develop/libraries/biosignal/README.md) |
| Mark-10 device communication, settings, samples, and units | [Mark-10](../develop/libraries/mark10/README.md) |
| Scientific operations owned by one app | [Apps](../apps/README.md) |

Module guides explain scope, data models, normal call sequences, algorithms, and representative examples. Function pages are the source for exact callable contracts. Files in `private/` directories and App helpers without a complete public help contract are not supported entry points.

## Compatibility

Each reusable library publishes a `version()` result. Apps declare compatible library ranges in the `Requirements` field of their single `definition.m` contract. A function documented here is public within that library version; compatibility across a breaking version is not implied.

The tables below are generated from current MATLAB source. Each entry links to the current function help.
