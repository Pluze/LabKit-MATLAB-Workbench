# Public API Reference

This index lists the supported app-facing MATLAB functions under `+labkit`.
Private implementation files are intentionally omitted. Open the facade page
for syntax, options, outputs, data shapes, and examples.

## Contract

[Contract reference](contracts.md): `labkit.contract` provides
`assertRequirements`, `checkRequirements`, `requirements`, and `versionInfo`.

## UI

[UI reference](ui.md)

- `labkit.ui.runtime`: `create`, `createPortableFileReference`,
  `defaultOutputFolder`, `define`, `emptySourceRecords`, `launch`, `loadState`,
  `resolvePortableFileReference`, `runBusy`, `saveState`
- `labkit.ui.layout`: `action`, `field`, `filePanel`, `group`, `logPanel`,
  `panner`, `previewArea`, `rangeField`, `resultTable`, `section`,
  `statusPanel`, `tab`, `workbench`, `workspace`
- `labkit.ui.plot`: `clampData`, `clear`, `fit`, `fitCanvas`, `message`,
  `offsetData`
- `labkit.ui.interaction`: `anchorPath`, `enablePopout`,
  `scaleBarCalibration`, `scaleBarGeometry`
- `labkit.ui.debug`: `context`
- `labkit.ui`: `version`

## Image

[Image reference](image.md): `adjustBrightnessContrast`,
`adjustHueSaturation`, `assertSupportedPaths`, `displayName`, `ensureRgb`,
`fileDialogFilter`, `grayWorldWhiteBalance`, `im2double`, `isSupportedPath`,
`localContrast`, `meanFilter2`, `normalizePaths`, `previewBudget`, `readFiles`,
`resizeToFit`, `rgb2gray`, `sharpen`, `supportedExtensions`, `version`, and
`writeFile`.

## Thermal

[Thermal reference](thermal.md): `fileDialogFilter`, `inspectFile`,
`isSupportedPath`, `rawToTemperatureC`, `readFile`, `readFiles`, `renderImage`,
`supportedExtensions`, and `version`.

## DTA

[DTA reference](dta.md): `detectPulses`, `detectType`, `findFiles`,
`getColumn`, `getCurveXY`, `getMainCurve`, `getZCurve`, `loadFile`, `loadFiles`,
`loadFolder`, and `version`.

## RHS

[RHS reference](rhs.md): `findFiles`, `indexFile`, `inspectFile`, `readWindow`,
and `version`.

## Biosignal

[Biosignal reference](biosignal.md): `buildTemplate`, `compareGroups`,
`cropSignal`, `defaultEcgPeakOptions`, `detectEcgPeaks`, `filterSignal`,
`getChannel`, `listChannels`, `measureSegments`, `readRecording`,
`segmentByEvents`, and `version`.

## API Stability

Facade `version()` functions publish MATLAB-native contract versions. Apps
declare compatible ranges in app-owned `requirements.m` files. Files under a
facade's `private/` directory are not supported entry points.

For task-oriented app behavior, use the [app guide](../apps/README.md) rather
than this function index.
