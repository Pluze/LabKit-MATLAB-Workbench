% Expected caller: the registered Image Match V2 renderer. Inputs are target
% axes and prepared image/title model. Side effects are limited to the axes.
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
    title(ax, char(model.title));
    xlabel(ax, '');
    ylabel(ax, '');
    box(ax, 'on');
end
