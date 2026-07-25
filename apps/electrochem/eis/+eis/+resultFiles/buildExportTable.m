% Expected caller: EIS result export and export tests. Inputs are EIS item
% structs, axis labels, and log flags. Output is the stable EIS export table.
% No file side effects.

function T = buildExportTable( ...
        items, xName, yName, impedanceUnit, useLogX, useLogY)
    if nargin < 4
        units = eis.impedanceDisplay.catalog();
        impedanceUnit = units.choices(3);
    end
    if nargin < 5
        useLogX = false;
    end
    if nargin < 6
        useLogY = false;
    end

    maxLen = 0;
    xCell = cell(1, numel(items));
    yCell = cell(1, numel(items));

    for i = 1:numel(items)
        [x, y] = filteredXY(items(i), xName, yName, ...
            impedanceUnit, useLogX, useLogY);
        xCell{i} = x(:);
        yCell{i} = y(:);
        maxLen = max(maxLen, numel(x));
    end

    T = table((1:maxLen).', 'VariableNames', {'RowIndex'});
    for i = 1:numel(items)
        safeName = matlab.lang.makeValidName(items(i).name);
        xVar = matlab.lang.makeValidName(sprintf('X_%s_%s', ...
            exportAxisName(xName, impedanceUnit), safeName));
        yVar = matlab.lang.makeValidName(sprintf('Y_%s_%s', ...
            exportAxisName(yName, impedanceUnit), safeName));
        T.(xVar) = padWithNaN(xCell{i}, maxLen);
        T.(yVar) = padWithNaN(yCell{i}, maxLen);
    end
end

function [x, y] = filteredXY( ...
        item, xName, yName, impedanceUnit, useLogX, useLogY)
    x = eis.analysisRun.valuesForAxis(item, xName, impedanceUnit);
    y = eis.analysisRun.valuesForAxis(item, yName, impedanceUnit);
    valid = isfinite(x) & isfinite(y);
    x = x(valid);
    y = y(valid);
    if useLogX
        validX = x > 0;
        x = x(validX);
        y = y(validX);
    end
    if useLogY
        validY = y > 0;
        x = x(validY);
        y = y(validY);
    end
end

function padded = padWithNaN(v, n)
    padded = NaN(n, 1);
    if isempty(v)
        return;
    end
    padded(1:numel(v)) = v(:);
end

function out = sanitizeAxisName(txt)
    out = regexprep(lower(txt), '[^a-z0-9]+', '_');
    out = regexprep(out, '^_+|_+$', '');
end

function out = exportAxisName(axisName, impedanceUnit)
out = sanitizeAxisName(axisName);
items = eis.overlayPlot.axisItems();
if ~any(string(axisName) == items(5:8))
    return
end
units = eis.impedanceDisplay.catalog();
index = find(string(impedanceUnit) == units.choices, 1);
if isempty(index)
    error("eis:InvalidImpedanceUnit", ...
        "Unsupported impedance display unit: %s.", impedanceUnit);
end
out = sprintf("%s_%s", out, units.exportTokens(index));
end
