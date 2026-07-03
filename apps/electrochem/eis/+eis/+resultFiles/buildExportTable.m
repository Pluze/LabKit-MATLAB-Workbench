% Expected caller: eis.definitionActions and export tests. Inputs are EIS item
% structs, axis labels, and log flags. Output is the stable EIS export table.
% No file side effects.

function T = buildExportTable(items, xName, yName, useLogX, useLogY)
    if nargin < 4
        useLogX = false;
    end
    if nargin < 5
        useLogY = false;
    end

    maxLen = 0;
    xCell = cell(1, numel(items));
    yCell = cell(1, numel(items));

    for i = 1:numel(items)
        [x, y] = filteredXY(items(i), xName, yName, useLogX, useLogY);
        xCell{i} = x(:);
        yCell{i} = y(:);
        maxLen = max(maxLen, numel(x));
    end

    T = table((1:maxLen).', 'VariableNames', {'RowIndex'});
    for i = 1:numel(items)
        safeName = matlab.lang.makeValidName(items(i).name);
        xVar = matlab.lang.makeValidName(sprintf('X_%s_%s', sanitizeAxisName(xName), safeName));
        yVar = matlab.lang.makeValidName(sprintf('Y_%s_%s', sanitizeAxisName(yName), safeName));
        T.(xVar) = padWithNaN(xCell{i}, maxLen);
        T.(yVar) = padWithNaN(yCell{i}, maxLen);
    end
end

function [x, y] = filteredXY(item, xName, yName, useLogX, useLogY)
    x = eis.analysisRun.valuesForAxis(item, xName);
    y = eis.analysisRun.valuesForAxis(item, yName);
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
