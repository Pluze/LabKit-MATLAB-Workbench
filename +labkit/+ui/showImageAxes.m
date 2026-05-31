function hImage = showImageAxes(ax, imageData, titleText, opts)
%SHOWIMAGEAXES Render an image in a UI axes with LabKit defaults.

    if nargin < 4
        opts = struct();
    end

    if optionValue(opts, 'clearAxes', true)
        cla(ax);
    end

    hImage = image(ax, imageData);
    hImage.HitTest = optionValue(opts, 'hitTest', 'off');
    hImage.PickableParts = optionValue(opts, 'pickableParts', 'none');

    axis(ax, 'image');
    ax.XLim = [0.5, size(imageData, 2) + 0.5];
    ax.YLim = [0.5, size(imageData, 1) + 0.5];
    ax.YDir = 'reverse';
    ax.XTick = [];
    ax.YTick = [];
    title(ax, titleText);

    if optionValue(opts, 'enableNavigation', true)
        enableImageNavigation(ax);
    end
    labkit.ui.enableAxesPopout(ax);
end

function enableImageNavigation(ax)
    try
        enableDefaultInteractivity(ax);
    catch
    end
    try
        ax.Interactions = zoomInteraction;
    catch
    end
    try
        ax.Toolbar.Visible = 'on';
    catch
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
