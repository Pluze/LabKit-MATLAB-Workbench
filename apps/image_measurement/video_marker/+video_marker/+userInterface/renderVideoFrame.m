% Expected caller: the registered Video Marker V2 renderer. Inputs are one
% semantic preview axes and a prepared frame/skeleton/scale model. Side effects
% are limited to non-pickable graphics on the supplied axes.
function renderVideoFrame(ax, model)
    view = captureImageView(ax, model.imageData);
    labkit.ui.plot.clear(ax, "ResetScale", true);
    if isempty(model.imageData)
        title(ax, char(model.title));
        box(ax, 'on');
        return;
    end
    if ndims(model.imageData) == 2
        imagesc(ax, model.imageData);
        colormap(ax, gray(256));
    else
        image(ax, model.imageData);
    end
    axis(ax, 'image');
    ax.YDir = 'reverse';
    hold(ax, 'on');
    drawSkeleton(ax, model.skeleton, model.points);
    drawScaleBar(ax, model.scaleBar);
    hold(ax, 'off');
    title(ax, char(model.title));
    xlabel(ax, '');
    ylabel(ax, '');
    box(ax, 'on');
    restoreImageView(ax, view);
end

function view = captureImageView(ax, imageData)
    view = struct("preserve", false, "xLimits", [], "yLimits", []);
    images = findobj(ax, 'Type', 'image');
    if isempty(images) || isempty(imageData)
        return;
    end
    previousSize = size(images(1).CData);
    nextSize = size(imageData);
    if numel(previousSize) < 2 || numel(nextSize) < 2 || ...
            ~isequal(previousSize(1:2), nextSize(1:2))
        return;
    end
    xLimits = double(ax.XLim);
    yLimits = double(ax.YLim);
    if numel(xLimits) ~= 2 || numel(yLimits) ~= 2 || ...
            any(~isfinite([xLimits yLimits])) || ...
            diff(xLimits) <= 0 || diff(yLimits) <= 0
        return;
    end
    view = struct("preserve", true, ...
        "xLimits", xLimits, "yLimits", yLimits);
end

function restoreImageView(ax, view)
    if ~view.preserve
        return;
    end
    ax.XLim = view.xLimits;
    ax.YLim = view.yLimits;
end

function drawSkeleton(ax, skeleton, points)
    for k = 1:size(skeleton.edges, 1)
        edge = skeleton.edges(k, :);
        if all(edge <= size(points, 1))
            plot(ax, points(edge, 1), points(edge, 2), '-', ...
                'Color', [0.1 0.65 1], 'LineWidth', 1.5, ...
                'HitTest', 'off', 'PickableParts', 'none');
        end
    end
    for k = 1:size(points, 1)
        text(ax, points(k, 1) + 4, points(k, 2) + 4, ...
            string(skeleton.pointNames(k)), ...
            'Color', [1 1 1], 'FontWeight', 'bold', ...
            'Interpreter', 'none', 'HitTest', 'off', ...
            'PickableParts', 'none');
    end
end

function drawScaleBar(ax, scaleBar)
    if isempty(scaleBar)
        return;
    end
    plot(ax, scaleBar.line(:, 1), scaleBar.line(:, 2), '-', ...
        'Color', scaleBar.color, 'LineWidth', 3, ...
        'HitTest', 'off', 'PickableParts', 'none');
    text(ax, scaleBar.labelPosition(1), scaleBar.labelPosition(2), ...
        scaleBar.label, 'Color', scaleBar.color, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', char(scaleBar.verticalAlignment), ...
        'HitTest', 'off', 'PickableParts', 'none');
end
