# Documentation Guide

This directory is organized around the repository's main component boundaries: UI library, DTA library, and app-owned workflow details.

## Component Docs

- `architecture.md`: package boundaries and ownership rules.
- `ui.md`: reusable MATLAB GUI shell, layout contract, and UI helper responsibilities.
- `dta.md`: current electrochemistry/Gamry DTA API, parser assumptions, and DTA structs.
- `apps.md`: app entry points, app-owned workflow rules, new-app starting patterns, and current app-specific notes.
- `testing.md`: automated checks and behavior-preservation coverage.

## Validation Docs

GitHub Actions runs the default non-GUI MATLAB suite for pushes and pull requests to `main`. Local GUI launch/layout checks remain documented in `testing.md` because interactive GUI workflows are intentionally validated by manual app use.

## Repository-Level Docs

- `../README.md`: project introduction and user-facing app entry points.
- `../AGENTS.md`: agent and maintainer operating rules.
- `../CHANGELOG.md`: release-facing change history.
