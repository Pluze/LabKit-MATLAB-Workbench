# Explicit category comparisons and persistent legend editing

```labkit-change
id: CHG-20260905-category-and-legend-editing
date: 2026-09-05
type: feat
compatibility: compatible
component: labkit_TTestWizard_app | 1.4.1 -> 1.5.0
component: labkit_FigureStudio_app | 0.9.0 -> 0.10.0
```

## Why

Editing observation labels individually made category renaming slow and coupled display order to the statistical reference. Figure Studio exposed global legend appearance but rebuilt legend content from the source, so presentation refreshes could erase local changes. Both workflows need explicit edit ownership and a visible mapping from the current objects to the desired presentation.

## What changed

[T-Test Wizard](../../use/apps/statistics/ttest-wizard/README.md) provides category-level renaming, batch names, empty destinations, selected-row assignment to a newly named category, category positions, an explicit reference, and comparison inclusion. Moving categories preserves the reference and within-category observation order. Plot brackets resolve the actual reference and comparison positions. Freshness checks compare snapshot inputs without running statistics during presentation.

[Figure Studio](../../use/apps/labkit-core/figure-studio/README.md) provides original-to-new legend names, independent row order, and inclusion checkboxes. Names and membership use the existing semantic objects; position is presentation metadata. Preview and export construct the edited legend from explicit graphics handles before applying appearance settings. Clearing every row suppresses automatic legend reconstruction. Edits participate in document history and remain separate from reusable global styles. Open figure creates an independent editable window from the complete current document, including every panel and its legend.

## Impact

Users can change category presentation and select the intended comparisons without rearranging numerical samples. Scientific results remain immutable until Run. Legend editing survives typography and style refreshes, panel duplication, popouts, and exports without modifying the original figure or data. These capabilities remain App-owned and use the existing framework table and callback contracts.

## Compatibility and limits

Statistical formulas, directional hypotheses, pairing by within-category row order, and CSV result fields remain unchanged. The programmatic first-versus-each t-test API remains supported. Newly added empty categories must receive sufficient observations or be excluded before running. Category names are unique ignoring case; legend labels may repeat. No multiple-comparison adjustment or inference of paired identities is introduced.

Unedited legends retain source behavior. Edited legend metadata is optional in the current semantic document; existing snapshots remain supported. Supported data-series objects can participate in the legend independently of plot stacking and visibility. Unsupported chart internals and real-data scientific suitability still require manual review.
