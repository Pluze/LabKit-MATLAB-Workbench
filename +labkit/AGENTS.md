# +labkit Agent Rules

`+labkit` is a small reusable library, not a dumping ground.

## Read Before Editing

- `docs/architecture.md`
- `docs/ui.md` for `+labkit/+ui`
- `docs/dta.md` for `+labkit/+dta`
- `docs/biosignal.md` for `+labkit/+biosignal`
- affected package tests under `tests/suites/labkit/`

## Boundary Rules

- Public API growth must be conservative.
- New public helpers must be domain-neutral, independently testable, useful beyond one workflow, and clearer as an API than as app-local code.
- Do not encode experiment-specific units, thresholds, result columns, plot wording, or export schemas in reusable helpers.
- Do not add public `+labkit/+analysis`, `+data`, `+io`, or `+util` app-facing surfaces.
- `labkit.dta` stays GUI-free and app-free.
- `labkit.biosignal` stays GUI-free and independent from DTA/app code.
- `labkit.ui` stays parser/data/analysis-free; apps pass prepared values, labels, tables, callbacks, and handles into UI helpers.
- Reusable UI tools may own domain-neutral interaction workflows such as image scale-bar controls, reference editing, unit normalization, and overlay placement. Keep those tools independent from app result schemas, scientific formulas, file formats, and workflow wording.
- Do not introduce MATLAB classes unless explicitly approved.

## Comments and Docs

- Public functions under `+labkit/+ui`, `+labkit/+dta`, and `+labkit/+biosignal` must document app-facing call contracts immediately after the function declaration.
- Private helpers must document expected caller, input/output shapes, side effects, and assumptions.
- Reusable API or package-boundary changes update the relevant human component doc and this file if agent rules change.
- Do not update this file for package implementation changes that preserve public contracts and boundary rules; state that docs/AGENTS were unchanged because contracts were preserved when the change is nontrivial.

## Validation Routing

- Always run `scripts/run_matlab_tests.sh --suite project` for package boundary or public surface changes.
- DTA changes: also run `scripts/run_matlab_tests.sh --suite labkit/dta`; add `--suite apps/electrochem` when app-facing behavior may be affected.
- Biosignal changes: also run `scripts/run_matlab_tests.sh --suite labkit/biosignal`; add `--suite apps/wearable` when app-facing behavior may be affected.
- UI changes: also run `scripts/run_matlab_tests.sh --suite labkit/ui`; add `--suite apps --gui` for layout, launch, callback, or app shell changes.
