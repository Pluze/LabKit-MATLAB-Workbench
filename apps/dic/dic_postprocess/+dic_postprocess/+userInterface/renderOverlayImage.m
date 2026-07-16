% Expected caller: the registered DIC Postprocess V2 renderer. Inputs are a
% target axes and prepared RGB overlay model. Side effects are limited to the
% supplied axes.
function renderOverlayImage(ax, model)
    labkit.ui.plot.clear(ax, "ResetScale", true);
    if isempty(model.imageData)
        title(ax, char(model.title));
        xlabel(ax, '');
        ylabel(ax, '');
        box(ax, 'on');
        return;
    end
    image(ax, model.imageData);
    axis(ax, 'image');
    ax.YDir = 'reverse';
    title(ax, char(model.title));
    xlabel(ax, '');
    ylabel(ax, '');
    box(ax, 'on');
end
