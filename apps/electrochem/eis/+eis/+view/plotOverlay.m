% Expected caller: EIS app runner. Inputs are an axes, EIS items, and plot
% options. Output is legend labels. Side effects are limited to redrawing axes.
function labels = plotOverlay(ax, items, opts)
    labels = eis.core.dispatch("plotOverlay", ax, items, opts);
end
