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
    drawScaleBar(ax, model.scaleBar);
    hold(ax, 'off');
    title(ax, char(model.title));
    xlabel(ax, '');
    ylabel(ax, '');
    box(ax, 'on');
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
