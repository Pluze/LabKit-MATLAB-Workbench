function rgb = renderImage(values, opts)
%RENDERIMAGE Render a thermal matrix as an RGB image.
%
% App-facing contract:
%   rgb = labkit.thermal.renderImage(values)
%   rgb = labkit.thermal.renderImage(values, opts)
%
% Inputs:
%   values - numeric thermal matrix.
%   opts - optional scalar struct with fields:
%       Limits - two finite increasing values. Default uses finite min/max.
%       Palette - "turbo", "parula", "hot", "gray", or "iron", default
%           "turbo".
%       Levels - positive integer colormap length, default 256.
%
% Outputs:
%   rgb - double MxNx3 image in [0, 1].

    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    opts = normalizeOptions(values, opts);
    values = double(values);
    scaled = (values - opts.Limits(1)) ./ diff(opts.Limits);
    scaled(~isfinite(scaled)) = 0;
    scaled = min(1, max(0, scaled));
    cmap = paletteMap(opts.Palette, opts.Levels);
    indices = floor(scaled .* (size(cmap, 1) - 1)) + 1;
    rgb = reshape(cmap(indices(:), :), [size(values, 1), size(values, 2), 3]);
end

function opts = normalizeOptions(values, opts)
    opts = struct( ...
        'Limits', optionValue(opts, 'Limits', finiteLimits(values)), ...
        'Palette', lower(string(optionValue(opts, 'Palette', "turbo"))), ...
        'Levels', double(optionValue(opts, 'Levels', 256)));
    if ~(isnumeric(opts.Limits) && numel(opts.Limits) == 2 && ...
            all(isfinite(opts.Limits)) && opts.Limits(2) > opts.Limits(1))
        error('labkit:thermal:InvalidOptions', ...
            'Limits must contain two finite increasing values.');
    end
    opts.Limits = double(opts.Limits(:)).';
    if ~any(opts.Palette == ["turbo", "parula", "hot", "gray", "iron"])
        error('labkit:thermal:InvalidOptions', ...
            'Unsupported thermal palette: %s', opts.Palette);
    end
    if ~(isfinite(opts.Levels) && opts.Levels >= 2)
        error('labkit:thermal:InvalidOptions', ...
            'Levels must be at least 2.');
    end
    opts.Levels = max(2, round(opts.Levels));
end

function limits = finiteLimits(values)
    finiteValues = double(values(isfinite(values)));
    if isempty(finiteValues)
        limits = [0 1];
        return;
    end
    lo = min(finiteValues);
    hi = max(finiteValues);
    if hi <= lo
        hi = lo + 1;
    end
    limits = [lo hi];
end

function cmap = paletteMap(name, levels)
    switch string(name)
        case "parula"
            cmap = parula(levels);
        case "hot"
            cmap = hot(levels);
        case "gray"
            cmap = gray(levels);
        case "iron"
            cmap = ironPalette(levels);
        otherwise
            cmap = turbo(levels);
    end
end

function cmap = ironPalette(levels)
    anchors = [
        0.00 0.00 0.00
        0.12 0.00 0.30
        0.45 0.00 0.45
        0.80 0.08 0.05
        1.00 0.55 0.00
        1.00 1.00 0.35
        1.00 1.00 1.00];
    x = linspace(0, 1, size(anchors, 1));
    xi = linspace(0, 1, levels);
    cmap = zeros(levels, 3);
    for k = 1:3
        cmap(:, k) = interp1(x, anchors(:, k), xi, 'linear');
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
