# Changelog

## Unreleased

- Added Phase 0 migration notes and initial project structure.
- Moved legacy GUI implementations under `legacy/` with root-level compatibility wrappers.
- Added `startup_gamrywb`.
- Extracted low-risk utility helpers into `+gamrywb/+util/`.
- Updated only the legacy multi-DTA overlay/export GUI to call extracted utilities where behavior is identical.
