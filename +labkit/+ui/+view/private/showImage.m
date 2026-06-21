% Private UI view helper. Expected caller: labkit.ui.view panel, control,
% plot, or text facades. Inputs and outputs are internal UI handles, labels,
% selections, table data, or plot info. Side effects are limited to supplied UI
% parents or axes; assumes the caller owns callbacks and app state.
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
%   enableNavigation - logical, default true; refreshes standard axes toolbar.
%                      Wheel zoom is owned by previewArea navigation.
%   preserveView - logical, default true. Preserves current XLim/YLim when
%                  redrawing an image with the same displayed image bounds.
%
% Output:
%   hImage - image graphics object. Axes popout is refreshed automatically.

    if nargin < 4
        opts = struct();
    end

    viewState = currentImageViewState(ax, imageData, ...
        optionValue(opts, 'preserveView', true));
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
    setappdata(ax, imageViewBoundsKey(), viewState.newBounds);
    if viewState.preserve
        ax.XLim = clampLimits(viewState.xLim, viewState.newBounds(1:2));
        ax.YLim = clampLimits(viewState.yLim, viewState.newBounds(3:4));
    end

    if optionValue(opts, 'enableNavigation', true)
        enableImageNavigation(ax);
    end
    labkit.ui.tool.enableAxesPopout(ax);
end

function enableImageNavigation(ax)
    try
        ax.Toolbar.Visible = 'on';
    catch
    end
end

function state = currentImageViewState(ax, imageData, preserveView)
    state = struct();
    state.newBounds = [0.5, size(imageData, 2) + 0.5, ...
        0.5, size(imageData, 1) + 0.5];
    state.xLim = [];
    state.yLim = [];
    state.preserve = false;
    if ~preserveView || ~isappdata(ax, imageViewBoundsKey())
        return;
    end
    oldBounds = getappdata(ax, imageViewBoundsKey());
    if ~isequal(size(oldBounds), [1 4]) || ...
            any(abs(double(oldBounds) - state.newBounds) > sqrt(eps))
        return;
    end
    state.xLim = ax.XLim;
    state.yLim = ax.YLim;
    state.preserve = numel(state.xLim) == 2 && numel(state.yLim) == 2 && ...
        all(isfinite(state.xLim)) && all(isfinite(state.yLim));
end

function limits = clampLimits(limits, fullLimits)
    span = diff(limits);
    fullSpan = diff(fullLimits);
    if span >= fullSpan
        limits = fullLimits;
        return;
    end
    if limits(1) < fullLimits(1)
        limits = [fullLimits(1), fullLimits(1) + span];
    end
    if limits(2) > fullLimits(2)
        limits = [fullLimits(2) - span, fullLimits(2)];
    end
end

function key = imageViewBoundsKey()
    key = 'labkitImageViewBounds';
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
