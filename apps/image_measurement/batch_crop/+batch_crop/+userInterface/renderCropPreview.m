% Expected caller: the registered Batch Crop V2 renderer. Inputs are a
% target axes and prepared preview/crosshair/scale-bar model. Side effects
% are limited to the supplied axes.
function renderCropPreview(ax, model)
    labkit.ui.plot.clear(ax, "ResetScale", true);
    if isempty(model.imageData)
        title(ax, char(model.title));
        xlabel(ax, '');
        ylabel(ax, '');
        box(ax, 'on');
        return;
    end
    if ndims(model.imageData) == 2
        imagesc(ax, model.xData, model.yData, model.imageData);
        colormap(ax, gray(256));
    else
        image(ax, model.xData, model.yData, model.imageData);
    end
    axis(ax, 'image');
    ax.YDir = 'reverse';
    hold(ax, 'on');
    center = model.center;
    plot(ax, [center(1) - 16, center(1) + 16], [center(2), center(2)], ...
        'Color', [0 0.85 1], 'LineWidth', 1.25, ...
        'HitTest', 'off', 'PickableParts', 'none');
    plot(ax, [center(1), center(1)], [center(2) - 16, center(2) + 16], ...
        'Color', [0 0.85 1], 'LineWidth', 1.25, ...
        'HitTest', 'off', 'PickableParts', 'none');
    drawCropRoi(ax, model.cropRectangle);
    drawScaleBar(ax, model.scaleBar);
    hold(ax, 'off');
    title(ax, char(model.title));
    xlabel(ax, '');
    ylabel(ax, '');
    box(ax, 'on');
end

function drawCropRoi(ax, position)
    if numel(position) ~= 4 || any(~isfinite(position)) || ...
            any(position(3:4) <= 0)
        return;
    end
    color = [1 0.9 0.15];
    rectangle(ax, 'Position', position, 'EdgeColor', color, ...
        'LineStyle', '-', 'LineWidth', 2, ...
        'HitTest', 'off', 'PickableParts', 'none');
    text(ax, position(1), max(0.5, position(2) - 3), 'Crop ROI', ...
        'Color', color, 'FontWeight', 'bold', ...
        'BackgroundColor', [0 0 0], 'Margin', 2, ...
        'HitTest', 'off', 'PickableParts', 'none');
end

function drawScaleBar(ax, scaleBar)
    if isempty(scaleBar)
        return;
    end
    plot(ax, scaleBar.line(:, 1), scaleBar.line(:, 2), '-', ...
        'Color', scaleBar.color, 'LineWidth', 3, ...
        'HitTest', 'off', 'PickableParts', 'none', ...
        'DisplayName', 'scale bar');
    text(ax, scaleBar.labelPosition(1), scaleBar.labelPosition(2), ...
        scaleBar.label, 'Color', scaleBar.color, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', char(scaleBar.verticalAlignment), ...
        'HitTest', 'off', 'PickableParts', 'none');
end
