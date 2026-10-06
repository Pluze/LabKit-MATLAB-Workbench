function draw(axesById, model)
%DRAW Render the clean thermal image, readings, and dedicated scale axis.
drawThermalImage(axesById.thermalImage, model);
drawTemperatureScale(axesById.temperatureScale, model);
end

function drawThermalImage(ax, model)
view = captureImageView(ax, model.values);
labkit.app.plot.clearAxes(ax);
if isempty(model.values)
    title(ax, char(model.title));
    box(ax, "on");
    return
end
rgb = flir_thermal.thermalPreview.presentationData.renderThermalImage( ...
    model.values, model.range, model.palette, ...
    model.colorMapping, model.gammaValue);
image(ax, rgb, HitTest="off", PickableParts="none");
axis(ax, "image");
ax.YDir = "reverse";
title(ax, char(model.title));
xlabel(ax, "");
ylabel(ax, "");
box(ax, "on");
flir_thermal.thermalPreview.presentationData.drawTemperatureReadings( ...
    ax, model.item);
restoreImageView(ax, view);
end

function drawTemperatureScale(ax, model)
labkit.app.plot.clearAxes(ax);
if isempty(model.values)
    title(ax, "Scale");
    box(ax, "on");
    return
end
range = double(model.range(:).');
values = linspace(range(1), range(2), 256).';
imageData = ...
    flir_thermal.thermalPreview.presentationData.renderThermalImage( ...
        repmat(values, 1, 12), range, model.palette, ...
        model.colorMapping, model.gammaValue);
image(ax, CData=imageData, XData=[0 1], YData=range, ...
    HitTest="off", PickableParts="none");
title(ax, "");
ax.DataAspectRatioMode = "auto";
ax.PlotBoxAspectRatioMode = "auto";
ax.XLim = [0 1];
ax.YLim = range;
ax.YDir = "normal";
ax.XTick = [];
ax.YTick = [range(1), mean(range), range(2)];
ax.YTickLabel = cellstr(string(compose("%.1f", ax.YTick)));
if string(model.units) == "C"
    ylabel(ax, "deg C");
else
    ylabel(ax, char(string(model.units)));
end
box(ax, "on");
end

function view = captureImageView(ax, values)
view = struct("preserve", false, "xLimits", [], "yLimits", []);
images = findobj(ax, "Type", "image");
if isempty(images) || isempty(values)
    return
end
previousSize = size(images(1).CData);
nextSize = size(values);
if numel(previousSize) < 2 || numel(nextSize) < 2 || ...
        ~isequal(previousSize(1:2), nextSize(1:2))
    return
end
view = struct("preserve", true, ...
    "xLimits", double(ax.XLim), "yLimits", double(ax.YLim));
end

function restoreImageView(ax, view)
if view.preserve
    ax.XLim = view.xLimits;
    ax.YLim = view.yLimits;
end
end
