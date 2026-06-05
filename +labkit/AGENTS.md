# +labkit Agent Rules

`+labkit` is a small reusable library, not a dumping ground.

## Read Before Editing

- `docs/architecture.md`
- `docs/ui.md` for `+labkit/+ui`
- `docs/dta.md` for `+labkit/+dta`
- `docs/biosignal.md` for `+labkit/+biosignal`
- affected package tests under `tests/unit/labkit/` or `tests/gui/structural/labkit/`

## Boundary Rules

- Public API growth must be conservative.
- New public helpers must be domain-neutral, independently testable, useful beyond one workflow, and clearer as an API than as app-local code.
- Do not encode experiment-specific units, thresholds, result columns, plot wording, or export schemas in reusable helpers.
- Do not add public `+labkit/+analysis`, `+data`, `+io`, or `+util` app-facing surfaces.
- `labkit.dta` stays GUI-free and app-free.
- `labkit.biosignal` stays GUI-free and independent from DTA/app code.
- `labkit.ui` stays parser/data/analysis-free; apps pass prepared values, labels, tables, callbacks, and handles into UI helpers.
- Reusable UI tools may own domain-neutral interaction workflows such as image scale-bar controls, reference editing, unit normalization, and overlay placement. Keep those tools independent from app result schemas, scientific formulas, file formats, and workflow wording.
- App-facing UI APIs live under `labkit.ui.app.*`, `labkit.ui.view.*`, `labkit.ui.tool.*`, and `labkit.ui.diag.*`. Do not reintroduce flat `labkit.ui.*` helper files.
- Image-axis tools that need pointer, drag, scroll, or hit-test ownership must use `labkit.ui.tool.createRuntime` sessions instead of each helper managing figure/axes callbacks independently.
- Tool callbacks must keep user-facing semantic callbacks separate from internal refresh/sync callbacks, no-op when a setter receives the current value, and trace callback reason/source when a tool exposes debug trace.
- Do not introduce MATLAB classes unless explicitly approved.

## Comments and Docs

- Public functions under `+labkit/+ui`, `+labkit/+dta`, and `+labkit/+biosignal` must document app-facing call contracts immediately after the function declaration.
- Private helpers must document expected caller, input/output shapes, side effects, and assumptions.
- Reusable API or package-boundary changes update the relevant human component doc and this file if agent rules change.
- Do not update this file for package implementation changes that preserve public contracts and boundary rules; state that docs/AGENTS were unchanged because contracts were preserved when the change is nontrivial.

## Validation Routing

Package boundary or public surface changes should include project guardrails.
Add the focused DTA, biosignal, or UI task for the touched facade, and add
downstream app-family tasks when the app-facing contract may be affected. Use
`docs/testing.md` for exact task names and GUI/non-GUI pairings.
