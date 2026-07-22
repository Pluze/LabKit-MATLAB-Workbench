%LIMITCONTROLS Derive editable X/Y limit values and legal data envelopes.
% Expected callers are Figure Studio source selection, limit actions, and
% presentation. The control envelope extends finite visible data by 50%.
function limits = limitControls(plotData)
%LIMITCONTROLS Build four scalar controls from one portable axes snapshot.
defaults = struct( ...
    "xMin", -1, "xMax", 1, "yMin", -1, "yMax", 1, ...
    "xRange", [-2 2], "yRange", [-2 2]);
if isempty(plotData) || ~isstruct(plotData) || ...
        ~isfield(plotData, "objects")
    limits = defaults;
    return;
end
[xData, yData] = visibleCoordinates(plotData.objects);
[xRange, xValues] = axisLimits(xData, axesValue(plotData, "xLim"));
[yRange, yValues] = axisLimits(yData, axesValue(plotData, "yLim"));
limits = struct( ...
    "xMin", xValues(1), "xMax", xValues(2), ...
    "yMin", yValues(1), "yMax", yValues(2), ...
    "xRange", xRange, "yRange", yRange);
end

function [xData, yData] = visibleCoordinates(objects)
xData = zeros(0, 1);
yData = zeros(0, 1);
for index = 1:numel(objects)
    object = objects(index);
    if ~isfield(object, "type") || any(string(object.type) == ...
            ["text", "rectangle"])
        continue;
    end
    xData = [xData; finiteReal(fieldValue(object, "x"))]; %#ok<AGROW>
    yData = [yData; finiteReal(fieldValue(object, "y"))]; %#ok<AGROW>
end
end

function [envelope, values] = axisLimits(data, stored)
data = finiteReal(data);
if isempty(data)
    data = finiteReal(stored);
end
if isempty(data)
    envelope = [-2 2];
    values = [-1 1];
    return;
end
minimum = min(data);
maximum = max(data);
span = maximum - minimum;
if span <= eps(max(1, max(abs([minimum maximum]))))
    span = max(1, abs(minimum));
end
padding = 0.5 * span;
envelope = [minimum - padding maximum + padding];
values = finitePair(stored);
if isempty(values) || values(1) < envelope(1) || values(2) > envelope(2)
    values = [minimum maximum];
    if values(1) == values(2)
        values = [minimum - 0.05 * span maximum + 0.05 * span];
    end
end
end

function value = axesValue(plotData, name)
value = [];
if isfield(plotData, "axes") && isstruct(plotData.axes) && ...
        isfield(plotData.axes, name)
    value = plotData.axes.(name);
end
end

function value = fieldValue(owner, name)
value = [];
if isstruct(owner) && isfield(owner, name)
    value = owner.(name);
end
end

function value = finiteReal(value)
if ~isnumeric(value)
    value = zeros(0, 1);
    return;
end
value = double(value(:));
value = value(isfinite(value) & isreal(value));
end

function value = finitePair(value)
value = finiteReal(value);
if numel(value) ~= 2 || value(1) >= value(2)
    value = [];
else
    value = reshape(value, 1, 2);
end
end
