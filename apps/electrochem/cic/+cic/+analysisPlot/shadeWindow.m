% Expected caller: CIC app plotting helpers. Inputs are an axes, x-window, and
% color. Side effects are limited to adding the app-owned patch to the axes.

function shadeWindow(ax, x1, x2, color)
    if ~isfinite(x1) || ~isfinite(x2) || x2 <= x1
        return;
    end
    yl = ylim(ax);
    patch(ax,[x1 x2 x2 x1],[yl(1) yl(1) yl(2) yl(2)],color, ...
        'FaceAlpha',0.25,'EdgeColor','none','HandleVisibility','off');
    uistack(findobj(ax,'Type','patch'),'bottom');
end
