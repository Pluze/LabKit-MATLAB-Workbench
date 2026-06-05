function hImage = showImage(ax, imageData, titleText, opts)
%SHOWIMAGEAXES Render an image in a UI axes with LabKit defaults.
%
% Usage:
%   hImage = showImage(ax, rgbImage, 'Reference');
%   hImage = showImage(ax, img, 'Mask', ...
%       struct('hitTest', 'on', 'pickableParts', 'all'));
%
% Inputs:
%   ax - target UI axes.
%   imageData - image array accepted by MATLAB image().
%   titleText - axes title.
%   opts - optional struct.
%
% Options:
%   clearAxes - logical, default true.
%   hitTest - image HitTest value, default "off".
%   pickableParts - image PickableParts value, default "none".
%   enableNavigation - logical, default true; enables image-style zoom tools.
%
% Output:
%   hImage - image graphics object. Axes popout is refreshed automatically.

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
    enablePopout(ax);
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
