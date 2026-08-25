# Legacy import preserves portable references without exposing their schema

```labkit-change
id: CHG-20260716-opaque-source-import
date: 2026-07-16
type: feat
compatibility: compatible
component: labkit.ui | 7.4.2 -> 7.4.3
```

## Why

The GUI-free source-record factory accepted filepaths, but an App importing an older MAT variable could already receive a portable reference containing the only usable relative location. Recreating the record from its original path would discard that portability; preserving it required the importer to copy the Runtime's private nested reference schema.

### Accepted choice

Keep one public source factory and allow its source value to be either a normal filepath or an existing portable reference passed as one opaque struct. The Runtime validates and canonicalizes the latter. Apps still never construct or read nested reference fields.

## What changed

- Extended `labkit.ui.runtime.sourceRecord` with an opaque-reference overload.
- Added strict validation for the supported portable-reference schema, scalar text fields, filename, and usable relative or original path.
- Canonicalized imported references so unrelated legacy fields do not enter a current project.
- Documented the distinction between normal filepath creation and legacy reference preservation.

## Impact

Moved legacy projects retain their relative source fallback during upgrade. App importers no longer need to duplicate Runtime serialization fields or choose between architectural ownership and data portability.

## Compatibility and limits

Existing filepath calls and injected source-record services are unchanged. The overload accepts only the current supported reference schema; malformed or newer references fail before they can enter a project.

### Remaining limits

Opaque-reference import is intended for trusted project importers, not as a general App-defined serialization extension. Video Marker is the first legacy importer scheduled to consume the overload.
