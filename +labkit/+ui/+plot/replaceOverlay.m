function handles = replaceOverlay(ax, layerId, drawFcn)
%REPLACEOVERLAY Replace one app-owned graphics layer without clearing an axes.
%
% App-facing contract:
%   handles = labkit.ui.plot.replaceOverlay(ax, layerId, drawFcn)
%
% Inputs:
%   ax - target MATLAB axes or uiaxes handle.
%   layerId - nonempty text scalar identifying one overlay layer on ax.
%   drawFcn - function handle called as drawFcn(ax). It returns graphics
%       handles, either as an array or cell array. Return [] to clear a layer.
%
% Output:
%   handles - cell array of valid graphics created for this layer.
%
% Contract:
%   Only graphics previously registered to layerId are deleted. Existing
%   background/peer graphics, axes limits and limit modes, hold state, and
%   figure/axes callbacks are preserved. The drawing callback owns styling,
%   hit testing, and pickability of its graphics.
%
% Example:
%   labkit.ui.plot.replaceOverlay(ax, "labels", ...
%       @(target) text(target, x, y, labels));

    validateAxesHandle(ax, 'replaceOverlay');
    id = string(layerId);
    if ~isscalar(id) || strlength(strtrim(id)) == 0
        error('labkit:ui:plot:InvalidOverlayId', ...
            'Overlay layer id must be a nonempty text scalar.');
    end
    if ~isa(drawFcn, 'function_handle')
        error('labkit:ui:plot:InvalidOverlayDrawFcn', ...
            'Overlay drawing callback must be a function handle.');
    end

    key = 'labkit_ui_plot_overlay_layers';
    layers = overlayLayers(ax, key);
    idx = find(layers.ids == id, 1);
    if isempty(idx)
        layers.ids(end + 1) = id;
        layers.handles{end + 1} = {};
        idx = numel(layers.ids);
    end
    deleteHandles(layers.handles{idx});

    view = captureView(ax);
    wasHeld = ishold(ax);
    cleanupObj = onCleanup(@() restoreAxes(ax, view, wasHeld));
    hold(ax, 'on');
    handles = normalizeHandles(drawFcn(ax));
    restoreAxes(ax, view, wasHeld);
    clear cleanupObj;

    layers.handles{idx} = handles;
    setappdata(ax, key, layers);
end

function layers = overlayLayers(ax, key)
    layers = struct('ids', strings(1, 0), 'handles', {{}});
    if isappdata(ax, key)
        candidate = getappdata(ax, key);
        if isstruct(candidate) && isfield(candidate, 'ids') && ...
                isfield(candidate, 'handles')
            layers = candidate;
        end
    end
end

function handles = normalizeHandles(value)
    if isempty(value)
        handles = {};
    elseif iscell(value)
        handles = value(:).';
    else
        handles = num2cell(value(:).');
    end
    keep = cellfun(@(h) ~isempty(h) && isgraphics(h) && isvalid(h), handles);
    handles = handles(keep);
end

function deleteHandles(handles)
    for k = 1:numel(handles)
        h = handles{k};
        if ~isempty(h) && isgraphics(h) && isvalid(h)
            delete(h);
        end
    end
end

function view = captureView(ax)
    view = struct( ...
        'xLim', ax.XLim, 'xLimMode', ax.XLimMode, ...
        'yLim', ax.YLim, 'yLimMode', ax.YLimMode, ...
        'zLim', ax.ZLim, 'zLimMode', ax.ZLimMode);
end

function restoreAxes(ax, view, wasHeld)
    if isempty(ax) || ~isvalid(ax)
        return;
    end
    ax.XLim = view.xLim;
    ax.YLim = view.yLim;
    ax.ZLim = view.zLim;
    ax.XLimMode = view.xLimMode;
    ax.YLimMode = view.yLimMode;
    ax.ZLimMode = view.zLimMode;
    if wasHeld
        hold(ax, 'on');
    else
        hold(ax, 'off');
    end
end
