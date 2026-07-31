% Expected caller: the registered DIC Preprocess App SDK renderer. Inputs are one
% semantic preview axes and prepared image/overlay model. Side effects are
% limited to the supplied axes; overlays never become semantic state.
function drawPreview(axesById, model)
drawOne(axesById.reference, model.reference);
drawOne(axesById.moving, model.moving);
end

function drawOne(ax, model)
    if isempty(model.imageData)
        labkit.app.plot.clearAxes(ax);
        title(ax, char(model.title));
        box(ax, 'on');
        return;
    end

    background = findobj(ax, 'Type', 'Image', 'Tag', backgroundTag());
    sameImage = isscalar(background) && isvalid(background) && ...
        isequaln(background.CData, model.imageData);
    if ~sameImage
        labkit.app.plot.clearAxes(ax);
        if ismatrix(model.imageData)
            background = imagesc(ax, model.imageData);
            colormap(ax, gray(256));
        else
            background = image(ax, model.imageData);
        end
        background.Tag = backgroundTag();
        axis(ax, 'image');
        ax.YDir = 'reverse';
    end

    delete(findobj(ax, 'Tag', overlayTag()));
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
        'Tag', overlayTag(), ...
        'HitTest', 'off', ...
        'PickableParts', 'none');
end

function drawPointLabels(ax, points)
    for k = 1:size(points, 1)
        text(ax, points(k, 1) + 4, points(k, 2), string(k), ...
            'Color', [0 0.85 1], ...
            'FontWeight', 'bold', ...
            'Tag', overlayTag(), ...
            'Clipping', 'on', ...
            'HitTest', 'off', ...
            'PickableParts', 'none');
    end
end

function value = backgroundTag()
    value = 'labkitDicPreprocessPreviewImage';
end

function value = overlayTag()
    value = 'labkitDicPreprocessPreviewOverlay';
end
