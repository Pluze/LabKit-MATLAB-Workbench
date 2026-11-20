# Visual design and export

## Size for the destination

Use the requested journal, template, or slide constraints first. Work at the physical size the reader will see. Without venue specs, use roughly 85–90 mm for single-column figures or 170–180 mm for a double-column composition. Adjust height for the chart and number of panels. A single LabKit-style plot can start near a 1.2–1.4:1 inner axes ratio. Equal-unit axes for geometry, long time series, and grid layouts may need different proportions. For presentation figures, size the plot for the slide region it will occupy and inspect it in that placement.

| Element | Starting range at publication size | Starting range at slide placement |
| --- | --- | --- |
| Tick and legend text | 7–9 pt | 14–20 pt |
| Axis labels | 8–10 pt | 16–24 pt |
| Titles and panel letters, when needed | 9–11 pt | 18–26 pt |
| Main data strokes | 1.0–1.6 pt | 1.6–2.5 pt |
| Uncertainty and boundaries | 0.6–1.0 pt | 0.9–1.5 pt |

These are practical fallback ranges, subject to venue and readability. Use one clear, available sans-serif such as Helvetica or Arial unless an established style calls for a different family. Check scientific symbols with the actual export font. Reserve space for text and legends outside the inner plot frame. Reflow panels before making type too small.

## Apply the LabKit visual hierarchy

- Start with a white background, dark axes and text, a complete plot frame, inward ticks, and a frameless legend. Omit grid lines by default. Use a light grid or omit part of the frame when that improves reading or follows the venue. Keep data strokes visually stronger than uncertainty, reference lines, and axes.
- Keep color meaning consistent across panels. Dark blue and burnt orange are useful default comparison colors. Distinguish conditions with marker shape, fill or line pattern as well as color. Use a sequential map for ordered magnitude and a diverging map with a meaningful midpoint. Share color limits for comparable quantities.
- Use the shortest labels that identify quantities and units. Match legend entries to the actual plotted marks, keep token lengths sufficient to distinguish line styles, and use direct labels when they reduce ambiguity. Move long methods, assumptions and citations to the caption. Leave a concise on-figure cue for estimates, thresholds, normalized baselines, censored bounds and display clipping when needed for interpretation.
- Align corresponding plot frames, ticks and panel headings. Use shared limits where reading magnitude across panels matters. If local scales are required to show detail, label them clearly and retain a common-scale overview when practical. Prefer a separate panel for a second quantity. Use a secondary axis for a direct unit conversion or a justified full-range overlay with explicit ruler-to-trace mapping.

The [Figure Studio manual](../../../../docs/use/apps/labkit-core/figure-studio/README.md) owns the exact LabKit preset and editable package contract. Its calibrated reference is an inner screen plot frame. Do not copy its literal pixel and point values into a print-size figure. Preserve the emphasis hierarchy and scale to the final destination.

## Export and inspect

- Use PDF or SVG for line art and editable text when the destination accepts it. Use raster data for dense image layers when appropriate, and a lossless PNG or TIFF where requested. Follow venue resolution requirements. In their absence, 300 dpi at final size is a useful starting point for raster panels. Use a higher resolution for rasterized line art when required. Do not enlarge a low-resolution render to meet a nominal dpi.
- Keep the analysis code or project, plotted data when needed, and final export traceable to one source. MATLAB workflows can save an editable FIG alongside vector or raster output. When Figure Studio is available, use its preflight and inspect the export. Native or other renderer workflows should perform equivalent data and layout checks.
- Inspect a real exported render or placed proof. Check for cropped tick labels or legends, swapped legend tokens, ambiguous dual rulers, unexpected rasterization or font substitutions, inaccessible contrast, visible clipping, and indistinguishable small marks. Inspect an editable file after reopening. A vector filename, a preflight pass, or an on-screen preview alone cannot establish the quality of the delivered figure.
