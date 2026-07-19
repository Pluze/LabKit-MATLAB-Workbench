% Expected caller: registered EIS plot renderer. Inputs are one axes
% and a prepared overlay model. Side effects are limited to supplied graphics.
function draw(axesById, model)
    ax = axesById.main;
    if model.hasItems
        eis.overlayPlot.plotOverlay(ax, model.items, model.options);
        return;
    end
    p = model.options;
    cla(ax, "reset");
    ax.XScale = scaleName(p.logX);
    ax.YScale = scaleName(p.logY);
    axis(ax, 'normal');
    title(ax, 'EIS Overlay');
    xlabel(ax, eis.overlayPlot.labelForAxis(p.xName));
    ylabel(ax, eis.overlayPlot.labelForAxis(p.yName));
end

function value = scaleName(useLog)
    if useLog
        value = 'log';
    else
        value = 'linear';
    end
end
