function [applied, frame] = fitCanvas(ax, width, height, varargin)
%FITCANVAS Fit one previewArea axes into a fixed pixel canvas frame.
%
% App-facing contract:
%   [applied, frame] = labkit.ui.plot.fitCanvas(ax, width, height, ...
%       "margin", marginPx, "maxScale", maxScale)
%
% Inputs:
%   ax - target UI axes hosted by a LabKit previewArea grid.
%   width, height - desired canvas size in pixels.
%   margin - optional parent-grid margin in pixels, default 24.
%   maxScale - optional maximum preview scale, default 1.
%
% Outputs:
%   applied - logical true when the axes was placed in a centered grid frame.
%   frame - struct with width, height, ratio, position, scale, and
%       pixelPosition fields. Empty struct when no frame could be applied.
%
% Example:
%   [ok, frame] = labkit.ui.plot.fitCanvas(ax, 720, 540);

    opts = parseOptions(varargin);
    frame = struct();
    applied = false;
    if isempty(ax) || ~isvalid(ax)
        return;
    end
    parent = ax.Parent;
    if isempty(parent) || ~isvalid(parent) || ...
            ~contains(class(parent), 'GridLayout')
        return;
    end

    canvasWidth = finiteScalar(width, NaN);
    canvasHeight = finiteScalar(height, NaN);
    if ~isfinite(canvasWidth) || ~isfinite(canvasHeight) || ...
            canvasWidth <= 0 || canvasHeight <= 0
        return;
    end

    try
        drawnow;
        parentPixels = getpixelposition(parent, true);
        margin = finiteScalar(opts.margin, 24);
        maxScale = finiteScalar(opts.maxScale, 1);
        availableWidth = max(1, parentPixels(3) - 2 * margin);
        availableHeight = max(1, parentPixels(4) - 2 * margin);
        if availableWidth < 240 || availableHeight < 180
            return;
        end

        scale = min(maxScale, min(availableWidth / canvasWidth, ...
            availableHeight / canvasHeight));
        frameWidth = max(1, round(canvasWidth * scale));
        frameHeight = max(1, round(canvasHeight * scale));
        parent.RowHeight = {'1x', frameHeight, '1x'};
        parent.ColumnWidth = {'1x', frameWidth, '1x'};
        ax.Layout.Row = 2;
        ax.Layout.Column = 2;
        frame = struct( ...
            'width', canvasWidth, ...
            'height', canvasHeight, ...
            'ratio', canvasWidth / canvasHeight, ...
            'position', [NaN NaN frameWidth frameHeight], ...
            'scale', scale, ...
            'pixelPosition', [NaN NaN frameWidth frameHeight]);
        applied = true;
    catch
        frame = struct();
        applied = false;
    end
end

function opts = parseOptions(args)
    opts = struct('margin', 24, 'maxScale', 1);
    if isempty(args)
        return;
    end
    if mod(numel(args), 2) ~= 0
        error('labkit:ui:plot:InvalidOptions', ...
            'fitCanvas options must be name/value pairs.');
    end
    for k = 1:2:numel(args)
        name = char(string(args{k}));
        if ~isfield(opts, name)
            error('labkit:ui:plot:InvalidOption', ...
                'Unsupported fitCanvas option "%s".', name);
        end
        opts.(name) = args{k + 1};
    end
end

function value = finiteScalar(candidate, fallback)
    value = fallback;
    if isempty(candidate)
        return;
    end
    candidate = double(candidate);
    if isscalar(candidate) && isfinite(candidate)
        value = candidate;
    end
end
