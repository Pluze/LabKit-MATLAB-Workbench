function rgb = renderImage(values, opts)
%RENDERIMAGE Map a thermal matrix to an RGB image.
%
% Usage:
%   rgb = labkit.thermal.renderImage(values)
%   rgb = labkit.thermal.renderImage(values, opts)
%
% Description:
%   Linearly maps numeric values between the selected limits onto a thermal
%   colour palette. Values below or above the limits are clipped to the first
%   or last palette colour. NaN and Inf values use the first palette colour.
%   This function changes only the display representation; it does not modify
%   the source temperatures or apply a calibration.
%
% Inputs:
%   values - Numeric M-by-N matrix containing temperatures or raw sensor
%       values.
%   opts - Optional scalar structure. See Options.
%
% Options:
%   Limits - Two finite, increasing numeric values [low high]. When omitted,
%       the finite minimum and maximum of values are used. An all-nonfinite
%       matrix uses [0 1]. A constant matrix uses [value value+1].
%   Palette - String scalar naming the colour palette. Allowed values are
%       "turbo", "parula", "hot", "gray", and "iron". Default: "turbo".
%   Levels - Finite numeric scalar giving the palette length. Values are
%       rounded to the nearest integer and must be at least 2. Default: 256.
%
% Outputs:
%   rgb - M-by-N-by-3 double array with channel values in the interval [0, 1].
%
% Errors:
%   Throws labkit:thermal:InvalidOptions when Limits, Palette, or Levels is
%   invalid.
%
% Example:
%   temperatureC = [20 24 28; 32 36 40];
%   rgb = labkit.thermal.renderImage(temperatureC, ...
%       struct("Limits", [20 40], "Palette", "iron", "Levels", 256));
%   assert(isequal(size(rgb), [2 3 3]))
%
% See also labkit.thermal.rawToTemperatureC,
%   labkit.thermal.readFile

    if nargin < 2
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
    validateOptionStruct(opts, ["Limits", "Palette", "Levels"]);
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
