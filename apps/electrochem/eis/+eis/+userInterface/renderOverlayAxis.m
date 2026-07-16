% Expected caller: registered EIS Runtime V2 renderer. Inputs are one axes
% and a prepared overlay model. Side effects are limited to supplied graphics.
function renderOverlayAxis(ax, model)
    if model.hasItems
        eis.userInterface.plotOverlay(ax, model.items, model.options);
        return;
    end
    p = model.options;
    labkit.ui.plot.clear(ax, "ResetScale", true);
    ax.XScale = scaleName(p.logX);
    ax.YScale = scaleName(p.logY);
    axis(ax, 'normal');
    title(ax, 'EIS Overlay');
    xlabel(ax, eis.userInterface.labelForAxis(p.xName));
    ylabel(ax, eis.userInterface.labelForAxis(p.yName));
end

function value = scaleName(useLog)
    if useLog
        value = 'log';
    else
        value = 'linear';
    end
end
