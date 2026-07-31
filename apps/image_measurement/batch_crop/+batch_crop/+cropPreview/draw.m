% Expected caller: the Batch Crop App SDK plot declaration. Inputs are a
% target axes and prepared preview/crosshair/scale-bar model. Side effects
% are limited to the supplied axes.
function draw(axesById, model)
    ax = axesById.main;
    labkit.app.plot.clearAxes(ax);
    if isempty(model.imageData)
        title(ax, char(model.title));
        xlabel(ax, '');
        ylabel(ax, '');
        box(ax, 'on');
        return;
    end
    if ismatrix(model.imageData)
        imagesc(ax, model.xData, model.yData, model.imageData);
        colormap(ax, gray(256));
    else
        image(ax, model.xData, model.yData, model.imageData);
    end
    axis(ax, 'image');
    ax.YDir = 'reverse';
    hold(ax, 'on');
    drawCropCenter(ax, model.center);
    drawCropRoiLabel(ax, model.cropRectangle);
    drawScaleBar(ax, model.scaleBar);
    hold(ax, 'off');
    title(ax, char(model.title));
    xlabel(ax, '');
    ylabel(ax, '');
    box(ax, 'on');
end

function drawCropCenter(ax, center)
    if numel(center) ~= 2 || any(~isfinite(center))
        return;
    end
    color = [1 0.9 0.15];
    plot(ax, center(1), center(2), 'o', ...
        'MarkerSize', 9, 'LineWidth', 1.5, ...
        'MarkerEdgeColor', color, 'MarkerFaceColor', 'none', ...
        'HitTest', 'off', 'PickableParts', 'none');
    text(ax, center(1) + 10, center(2) - 10, 'Crop center', ...
        'Color', color, 'FontWeight', 'bold', ...
        'BackgroundColor', [0 0 0], 'Margin', 2, ...
        'HitTest', 'off', 'PickableParts', 'none');
end

function drawCropRoiLabel(ax, position)
    if numel(position) ~= 4 || any(~isfinite(position)) || ...
            any(position(3:4) <= 0)
        return;
    end
    text(ax, position(1), max(0.5, position(2) - 3), ...
        'Crop ROI — drag center or inside box', ...
        'Color', [1 0.9 0.15], 'FontWeight', 'bold', ...
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
