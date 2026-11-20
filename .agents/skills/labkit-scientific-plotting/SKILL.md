---
name: labkit-scientific-plotting
description: "Use proactively to design, analyze, render, or revise standalone scientific data plots and publication figures for papers, theses, reports, or research slides. Applies when the agent must choose a plot, comparison, layout, or export. LabKit product-code and scientific-contract changes use their existing workflows."
---

# LabKit Scientific Plotting

Produce a figure that answers the research question, survives reproduction, and remains legible at its intended size. This Skill owns standalone figure work even when LabKit was used to process the data. Choose the user's or project's plotting environment. A MATLAB or Figure Studio dependency is optional.

## Establish the comparison

- Identify the reader, question, comparison, figure destination, and any required dimensions, units, or formats. Use the target journal's figure instructions or the actual slide geometry when provided. Otherwise choose a reversible default and report the assumption.
- Inspect source schema, units, channel meanings, sampling and calibration, replicate or pairing identifiers, missing values, and instrument limits as applicable. Resolve consequential ambiguity before making a scientific claim. Keep an editable neutral label or a diagnostic plot useful while missing metadata is resolved.
- Decide what each mark represents and what should be visible in the caption. Keep measured observations, fitted curves, literature values, simulations, and hypothetical scenarios identifiable. Define the independent unit and the uncertainty display. Retain pairing and nesting when they affect interpretation.
- Select the figure form from the question. Use points and distributions for group comparisons, numeric positions for dose or time, measured points with labeled model curves for fits, and matched axes for waveform, spectrum, or condition comparisons. Use a primary view and a linked detail only when both answer distinct questions.

## Analyze and draw

Read [analysis decisions](references/analysis.md) when choosing statistics, fitting models, selecting regions of interest, estimating spectra or SNR, converting scientific units, or handling censored or modeled data. Skip re-analysis for a style-only revision and check that coordinates, uncertainty and category meanings survive the edit.

Read [visual design and export](references/visual-design.md) when setting physical sizes, applying the LabKit style, editing an existing figure, or deciding how to deliver publication assets. Use a scientific plotting renderer with editable data marks and text. Reuse an applicable script, style, or figure project. Choose the renderer according to existing project dependencies and the requested format.

## Verify and deliver

- Validate displayed values against the source or plotted-data table. Check representative mark positions, displayed units, group counts, uncertainty, domain limits, and legend-to-series mapping. For a style-only revision, compare the before and after plotted data.
- Render the exported figure and inspect it at intended placement size. Check margins, font and glyph rendering, readability, legend mapping, ticks, limits, panel alignment, and color and line-style distinctions. Reopen any promised editable artifact. Fix plot, layout, or export problems at the source and render again.
- Deliver the requested figure and its relevant editable or vector form. For a new analysis, retain the generating code or reproducible project and enough caption or methods information to reconstruct the plotted results. Make paths portable, keep source inputs read-only, and give each output variant a single writer or distinct name. Report what was calculated, what was visually checked, and any acquisition or scientific uncertainty that affects interpretation.
- Keep private inputs and derived lab figures in the approved local output location. Editable figures can embed data. Use synthetic values in repository examples and exclude real lab data, identifiers, and local paths from tracked changes.

When the task changes LabKit application or framework plotting, use its existing product workflow. Use `labkit-app-builder` for substantial App authoring, the scoped App or framework rules for maintenance, and `labkit-scientific-change-guard` when scientific behavior changes. A standalone figure request does not authorize those changes.
