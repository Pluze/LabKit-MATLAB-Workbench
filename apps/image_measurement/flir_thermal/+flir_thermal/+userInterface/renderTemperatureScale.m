% Expected caller: the registered FLIR V2 renderer. Inputs are target axes
% and a prepared thermal model. Side effects are limited to drawing the scale.
function renderTemperatureScale(ax, model)
    if isempty(model.values)
        labkit.ui.plot.clear(ax, "ResetScale", true, "ClearLegend", false);
        title(ax, 'Scale');
        box(ax, 'on');
        return;
    end
    range = double(model.range(:).');
    values = linspace(range(1), range(2), 256).';
    imageData = flir_thermal.userInterface.renderThermalImage( ...
        repmat(values, 1, 12), range, model.palette, ...
        model.colorMapping, model.gammaValue);
    labkit.ui.plot.clear(ax, "ResetScale", true, "ClearLegend", false);
    image(ax, 'CData', imageData, 'XData', [0 1], 'YData', range);
    title(ax, '');
    ax.DataAspectRatioMode = 'auto';
    ax.PlotBoxAspectRatioMode = 'auto';
    ax.XLim = [0 1];
    ax.YLim = range;
    ax.YDir = 'normal';
    ax.XTick = [];
    ax.YTick = [range(1), mean(range), range(2)];
    ax.YTickLabel = cellstr(string(compose('%.1f', ax.YTick)));
    if string(model.units) == "C"
        ylabel(ax, 'deg C');
    else
        ylabel(ax, char(string(model.units)));
    end
end
