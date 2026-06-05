% Expected caller: chrono overlay app runner. Inputs are voltage/current axes,
% aligned item structs, and plot option fields. Side effects are limited to
% redrawing the supplied axes.
function plotVTIT(axV, axI, items, opts)
    chrono_overlay.core.dispatch("plotVTIT", axV, axI, items, opts);
end
