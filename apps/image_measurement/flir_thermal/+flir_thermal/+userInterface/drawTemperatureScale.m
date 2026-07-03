% Expected caller: FLIR preview refresh. Inputs are the UI registry, display
% range, units, palette, color-mapping mode, and gamma value. Side effect is
% redrawing only the preview temperature scale axes.

function drawTemperatureScale(ui, range, units, palette, colorMapping, gammaValue)
%DRAWTEMPERATURESCALE Redraw the FLIR preview color scale.

    values = linspace(range(1), range(2), 256).';
    imageData = flir_thermal.userInterface.renderThermalImage( ...
        repmat(values, 1, 12), range, palette, colorMapping, gammaValue);
    ax = ui.controls.preview.axesById.temperatureScale;
    cla(ax);
    image(ax, 'CData', imageData, 'XData', [0 1], 'YData', range);
    title(ax, '');
    ax.DataAspectRatioMode = 'auto';
    ax.PlotBoxAspectRatioMode = 'auto';
    ax.XLim = [0 1];
    ax.YLim = [range(1) range(2)];
    ax.YDir = 'normal';
    ax.XTick = [];
    ax.YTick = [range(1), mean(range), range(2)];
    ax.YTickLabel = cellstr(string(compose('%.1f', ax.YTick)));
    if units == "C"
        ylabel(ax, 'deg C');
    else
        ylabel(ax, char(units));
    end
end
