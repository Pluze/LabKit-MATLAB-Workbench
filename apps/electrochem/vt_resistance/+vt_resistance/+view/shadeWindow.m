% Expected caller: VT resistance app plotting helpers. Inputs are an axes,
% x-window, color, and optional alpha. Side effects are limited to axes drawing.
function shadeWindow(ax, x1, x2, color, alpha)
    if nargin < 5
        vt_resistance.core.dispatch("shadeWindow", ax, x1, x2, color);
    else
        vt_resistance.core.dispatch("shadeWindow", ax, x1, x2, color, alpha);
    end
end
