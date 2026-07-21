% Expected caller: registered EIS plot renderer. Inputs are one axes
% and a prepared overlay model. Side effects are limited to supplied graphics.
function draw(axesById, model)
    ax = axesById.main;
    if model.hasItems
        eis.overlayPlot.plotOverlay(ax, model.items, model.options);
    else
        p = model.options;
        labkit.app.plot.clearAxes(ax, ResetScale=true);
        ax.XScale = scaleName(p.logX);
        ax.YScale = scaleName(p.logY);
        title(ax, 'EIS Overlay');
        xlabel(ax, eis.overlayPlot.labelForAxis(p.xName));
        ylabel(ax, eis.overlayPlot.labelForAxis(p.yName));
    end
    if model.viewAction == "equal"
        labkit.app.plot.fitAxesToGraphics(ax, EqualDataUnits=true);
    end
end

function value = scaleName(useLog)
    if useLog
        value = 'log';
    else
        value = 'linear';
    end
end
