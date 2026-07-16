% Expected caller: the registered FLIR V2 renderer. Inputs are target axes
% and a prepared thermal model. Side effects are limited to drawing the axes.
function renderThermalPreview(ax, model)
    labkit.ui.plot.clear(ax, "ResetScale", true);
    if isempty(model.values)
        title(ax, char(model.title));
        box(ax, 'on');
        return;
    end
    rgb = flir_thermal.userInterface.renderThermalImage( ...
        model.values, model.range, model.palette, ...
        model.colorMapping, model.gammaValue);
    image(ax, rgb);
    axis(ax, 'image');
    ax.YDir = 'reverse';
    title(ax, char(model.title));
    xlabel(ax, '');
    ylabel(ax, '');
    box(ax, 'on');
    flir_thermal.userInterface.drawTemperatureReadings(ax, model.item);
end
