% Expected caller: the registered DIC Preprocess V2 renderer. Inputs are one
% semantic preview axes and prepared image/overlay model. Side effects are
% limited to the supplied axes; overlays never become semantic state.
function renderPreviewImage(ax, model)
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
    drawRectangle(ax, model.rectangle);
    drawPointLabels(ax, model.pointLabels);
    hold(ax, 'off');
    title(ax, char(model.title));
    xlabel(ax, '');
    ylabel(ax, '');
    box(ax, 'on');
end

function drawRectangle(ax, position)
    if isempty(position)
        return;
    end
    rectangle(ax, ...
        'Position', position, ...
        'EdgeColor', [1 0.85 0], ...
        'LineWidth', 1.5, ...
        'LineStyle', '--', ...
        'HitTest', 'off', ...
        'PickableParts', 'none');
end

function drawPointLabels(ax, points)
    for k = 1:size(points, 1)
        text(ax, points(k, 1) + 4, points(k, 2), string(k), ...
            'Color', [0 0.85 1], ...
            'FontWeight', 'bold', ...
            'HitTest', 'off', ...
            'PickableParts', 'none');
    end
end
