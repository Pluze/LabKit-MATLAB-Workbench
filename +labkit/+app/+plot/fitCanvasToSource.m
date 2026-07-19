function [applied, frame] = fitCanvasToSource(ax, width, height, varargin)
%FITCANVASTOSOURCE Fit a preview axes into a fixed-aspect pixel frame.
%
% Usage:
%   [applied, frame] = labkit.app.plot.fitCanvasToSource(ax, width, height)
%   [applied, frame] = labkit.app.plot.fitCanvasToSource(..., Name=Value)
%
% Inputs:
%   ax - UI axes whose parent is a uigridlayout created for a LabKit preview.
%   width - Positive finite source-canvas width in pixels.
%   height - Positive finite source-canvas height in pixels.
%
% Name-Value Arguments:
%   margin - Preferred empty margin around the frame in pixels. Default: 24.
%   maxScale - Largest allowed ratio between displayed and source dimensions.
%       Default: 1, so the helper does not enlarge the source canvas.
%
% Outputs:
%   applied - true when the grid and axes positions were updated; false when
%       the axes, parent grid, dimensions, or available space were unsuitable.
%   frame - Scalar struct with width, height, ratio, position, scale, and
%       pixelPosition fields. It is an empty struct when applied is false.
%
% Description:
%   fitCanvas centers the axes in the middle row and column of a three-by-three
%   flexible grid and preserves the requested aspect ratio. It returns false
%   instead of throwing when the host has not been laid out yet or is smaller
%   than the minimum usable preview area.
%
% Failure Behavior:
%   Invalid axes, host grids, source dimensions, or insufficient available
%   space return applied=false and frame=struct(). Malformed or unsupported
%   name-value arguments throw labkit:app:plot:InvalidOptions or
%   labkit:app:plot:InvalidOption.
%
% Typical Call:
%   [ok, frame] = labkit.app.plot.fitCanvasToSource(ax, 720, 540);
%
% See also labkit.app.layout.plotArea

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
        error('labkit:app:plot:InvalidOptions', ...
            'fitCanvas options must be name/value pairs.');
    end
    for k = 1:2:numel(args)
        name = char(string(args{k}));
        if ~isfield(opts, name)
            error('labkit:app:plot:InvalidOption', ...
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
