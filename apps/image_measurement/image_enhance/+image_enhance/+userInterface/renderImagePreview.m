% Expected caller: the registered Image Enhance V2 renderer. Inputs are a
% target axes and prepared image/ROI model. Side effects touch only the axes.
function renderImagePreview(ax, model)
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
    if ~isempty(model.whiteRoi)
        hold(ax, 'on');
        rectangle(ax, 'Position', model.whiteRoi, ...
            'EdgeColor', [1 1 1], 'LineWidth', 1.5, ...
            'HitTest', 'off', 'PickableParts', 'none');
        hold(ax, 'off');
    end
    title(ax, char(model.title));
    xlabel(ax, '');
    ylabel(ax, '');
    box(ax, 'on');
end
