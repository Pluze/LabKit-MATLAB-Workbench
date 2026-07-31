% DIC Postprocess ops helper. Expected caller: dic_postprocess.analysisRun.strainToRgb.
% Inputs are a strain map and valid map. Output fills invalid ROI pixels from
% nearest valid strain samples. Side effects: none.
function Sfilled = extendStrainMapToRoi(S, validMap)
    validMap = logical(validMap) & isfinite(S);
    Sfilled = S;
    if ~any(validMap(:))
        Sfilled(:) = NaN;
        return;
    end

    invalid = ~validMap;
    if ~any(invalid(:))
        return;
    end
    Sfilled(invalid) = nearestValidValues(S, validMap, invalid);
end

function values = nearestValidValues(S, validMap, invalid)
    [validRows, validCols] = find(validMap);
    validValues = S(validMap);
    [invalidRows, invalidCols] = find(invalid);

    if isscalar(validValues)
        values = repmat(validValues, size(invalidRows));
        return;
    end

    try
        interpolant = scatteredInterpolant( ...
            double(validCols), double(validRows), double(validValues), ...
            'nearest', 'nearest');
        values = interpolant(double(invalidCols), double(invalidRows));
        return;
    catch
        % Fall through to a toolbox-free nearest-neighbor search for narrow
        % or degenerate valid-sample layouts.
    end

    values = zeros(size(invalidRows), 'like', S);
    validRows = double(validRows(:).');
    validCols = double(validCols(:).');
    chunkSize = 512;
    for first = 1:chunkSize:numel(invalidRows)
        last = min(first + chunkSize - 1, numel(invalidRows));
        rows = double(invalidRows(first:last));
        cols = double(invalidCols(first:last));
        d2 = (rows - validRows).^2 + (cols - validCols).^2;
        [~, nearest] = min(d2, [], 2);
        values(first:last) = validValues(nearest);
    end
end
