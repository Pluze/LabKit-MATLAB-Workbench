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
        displayGamma = flir_thermal.thermalPreview.presentationData.normalizeGammaValue(gammaValue);
        mapped = scaled .^ (1 / displayGamma);
    end
    rgb = labkit.thermal.renderImage(mapped, ...
        struct("Limits", [0 1], "Palette", palette));
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
