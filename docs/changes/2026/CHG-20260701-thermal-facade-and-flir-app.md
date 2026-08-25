# Thermal facade and FLIR app

```labkit-change
id: CHG-20260701-thermal-facade-and-flir-app
date: 2026-07-01
type: feat
compatibility: compatible
component: labkit.thermal | new -> 1.0.0
component: labkit.ui | 3.2.9 -> 3.2.10
component: labkit_FLIRThermal_app | new -> 1.0.0
```

## Why

FLIR radiometric JPEGs contain both a visible preview and embedded thermal data plus camera metadata. Treating them as ordinary images loses the temperature meaning, while placing all parsing and conversion code inside one GUI would make the scientific operations unusable from MATLAB scripts.

### Accepted choice

Create a thermal library for reading radiometric files, converting raw sensor values to temperature, and rendering temperature images. Build the FLIR Thermal Postprocess app on those public operations, keeping file lists, range controls, measurement state, and export flow in the app.

## What changed

- `labkit.thermal` `1.0.0`
- `labkit_FLIRThermal_app` `1.0.0`

- Added the thermal facade.
- Added the FLIR Thermal Postprocess app.

## Impact

Users gained a FLIR app with file browsing, temperature display, range control, summary values, and export-oriented views. The same thermal functions could be called without opening the GUI, so scripts could inspect temperature matrices and metadata directly.

## Compatibility and limits

The thermal facade and FLIR app were additive. Existing image apps and files were unchanged; scripts could begin using `labkit.thermal` without a project- file migration.

### Remaining limits

Camera-specific metadata support depended on the formats represented by the synthetic and available local samples. Later changes refined display ranges, preview cost, and point and ROI measurement tools.
