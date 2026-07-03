% Expected caller: FLIR preview/export rendering. Inputs are a temperature
% matrix, display range, palette name, color-mapping mode, and optional gamma
% value. Output is RGB display data only; the source temperature matrix is
% never transformed.

function rgb = renderThermalImage(values, range, palette, colorMapping, gammaValue)
%RENDERTHERMALIMAGE Render FLIR values with linear, log, or gamma colors.

    if nargin < 4
        colorMapping = "Linear";
    end
    if nargin < 5
        gammaValue = 2.2;
    end
    colorMapping = lower(string(colorMapping));
    if ~any(colorMapping == ["log", "gamma"])
        rgb = labkit.thermal.renderImage(values, ...
            struct('Limits', range, 'Palette', palette));
        return;
    end

    values = double(values);
    range = normalizeRange(range);
    scaled = (values - range(1)) ./ diff(range);
    scaled(~isfinite(scaled)) = 0;
    scaled = min(1, max(0, scaled));

    if colorMapping == "log"
        curveStrength = 99;
        mapped = log1p(curveStrength * scaled) ./ log1p(curveStrength);
    else
        displayGamma = flir_thermal.userInterface.normalizeGammaValue(gammaValue);
        mapped = scaled .^ (1 / displayGamma);
    end
    cmap = paletteMap(palette, 256);
    indices = floor(mapped .* (size(cmap, 1) - 1)) + 1;
    rgb = reshape(cmap(indices(:), :), [size(values, 1), size(values, 2), 3]);
end

function range = normalizeRange(range)
    range = double(range(:)).';
    if numel(range) ~= 2 || ~all(isfinite(range))
        range = [0 1];
    end
    range = sort(range);
    if range(2) <= range(1)
        range(2) = range(1) + 1;
    end
end

function cmap = paletteMap(name, levels)
    switch lower(string(name))
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
