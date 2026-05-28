# Architecture

The target architecture is a thin GUI layer over reusable `gamrywb` package functions.

Current Phase 0-1 status:

- Legacy GUI behavior is preserved in `legacy/`.
- Package work has started with low-risk utilities under `+gamrywb/+util/`.
- Parsers, analysis functions, plotting helpers, and export builders remain in the legacy GUI files until later phases.
