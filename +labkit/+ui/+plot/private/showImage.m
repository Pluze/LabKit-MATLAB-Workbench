% Private UI plot helper. Expected caller: labkit.ui.control or labkit.ui.plot panel, control,
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
%   reuseImage - logical, default true. Reuses the previous LabKit image
%                object while clearing non-image overlay graphics.
%   xData, yData - optional two-element image XData/YData center coordinates.
%
% Output:
%   hImage - image graphics object. Axes popout is refreshed automatically.

    if nargin < 4
        opts = struct();
    end

    xData = optionValue(opts, 'xData', [1, size(imageData, 2)]);
    yData = optionValue(opts, 'yData', [1, size(imageData, 1)]);
    viewState = currentImageViewState(ax, imageData, xData, yData, ...
        optionValue(opts, 'preserveView', true));
    hImage = [];
    if optionValue(opts, 'clearAxes', true)
        hImage = reusableImage(ax, optionValue(opts, 'reuseImage', true));
        if isempty(hImage)
            cla(ax);
        else
            clearNonReusableChildren(ax, hImage);
        end
    end

    if isempty(hImage)
        hImage = image(ax, 'CData', imageData, 'XData', xData, 'YData', yData);
        hImage.Tag = imageObjectTag();
    else
        hImage.CData = imageData;
        hImage.XData = xData;
        hImage.YData = yData;
    end
    hImage.HitTest = optionValue(opts, 'hitTest', 'off');
    hImage.PickableParts = optionValue(opts, 'pickableParts', 'none');

    axis(ax, 'image');
    ax.XLim = viewState.newBounds(1:2);
    ax.YLim = viewState.newBounds(3:4);
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
    labkit.ui.interaction.enablePopout(ax);
end

function hImage = reusableImage(ax, reuseImage)
    hImage = [];
    if ~reuseImage
        return;
    end
    candidates = findobj(ax, 'Type', 'image', 'Tag', imageObjectTag());
    if isempty(candidates)
        return;
    end
    hImage = candidates(1);
end

function clearNonReusableChildren(ax, hImage)
    children = ax.Children;
    for k = 1:numel(children)
        child = children(k);
        if ~isequal(child, hImage) && isvalid(child)
            delete(child);
        end
    end
end

function enableImageNavigation(ax)
    try
        ax.Toolbar.Visible = 'on';
    catch
    end
end

function state = currentImageViewState(ax, imageData, xData, yData, preserveView)
    state = struct();
    state.newBounds = [imageDataLimits(xData, size(imageData, 2)), ...
        imageDataLimits(yData, size(imageData, 1))];
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

function limits = imageDataLimits(data, count)
    data = double(data(:)).';
    if numel(data) < 2 || count <= 1
        center = data(1);
        limits = center + [-0.5, 0.5];
        return;
    end
    step = abs(diff(data(1:2))) / max(1, count - 1);
    limits = sort(data(1:2)) + [-0.5, 0.5] .* step;
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

function tag = imageObjectTag()
    tag = 'LabKitViewImage';
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
