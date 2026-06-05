% Expected caller: CIC app plotting helpers. Inputs are an axes, x-window, and
% color. Side effects are limited to adding the app-owned patch to the axes.
function shadeWindow(ax, x1, x2, color)
    cic.core.dispatch("shadeWindow", ax, x1, x2, color);
end
