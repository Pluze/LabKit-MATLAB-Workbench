# Changelog

## Unreleased

- Began Phase 2 by extracting chrono DTA parsing, recursive DTA discovery, and main-curve/column accessors.
- Updated the legacy multi-DTA overlay/export GUI to use the extracted chrono parser and data accessors.
- Extracted EIS DTA parsing and ZCURVE accessors, then updated the legacy EIS overlay GUI to use them.
- Extracted CV/CT DTA parsing and updated the legacy CV/CSC GUI to use it.
- Added Phase 0 migration notes and initial project structure.
- Moved legacy GUI implementations under `legacy/` with root-level compatibility wrappers.
- Added `startup_gamrywb`.
- Extracted low-risk utility helpers into `+gamrywb/+util/`.
- Updated only the legacy multi-DTA overlay/export GUI to call extracted utilities where behavior is identical.
