%LIMITCONTROLS Derive editable X/Y limit values and finite control bounds.
% Expected callers are Figure Studio source selection, limit actions, and
% presentation. Axis limits are presentation choices, not data-derived policy.
function limits = limitControls(plotData)
%LIMITCONTROLS Build four scalar controls from one portable axes snapshot.
defaults = struct( ...
    "xMin", -1, "xMax", 1, "yMin", -1, "yMax", 1, ...
    "xRange", numericBounds(), "yRange", numericBounds());
if isempty(plotData) || ~isstruct(plotData) || ...
        ~isfield(plotData, "objects")
    limits = defaults;
    return;
end
[xData, yData] = visibleCoordinates(plotData.objects);
xValues = axisLimits(xData, axesValue(plotData, "xLim"));
yValues = axisLimits(yData, axesValue(plotData, "yLim"));
limits = struct( ...
    "xMin", xValues(1), "xMax", xValues(2), ...
    "yMin", yValues(1), "yMax", yValues(2), ...
    "xRange", numericBounds(), "yRange", numericBounds());
end

function [xData, yData] = visibleCoordinates(objects)
xParts = cell(numel(objects), 1);
yParts = cell(numel(objects), 1);
for index = 1:numel(objects)
    object = objects(index);
    if ~isfield(object, "type") || any(string(object.type) == ...
            ["text", "rectangle"])
        continue;
    end
    xParts{index} = finiteReal(fieldValue(object, "x"));
    yParts{index} = finiteReal(fieldValue(object, "y"));
end
xData = vertcat(xParts{:});
yData = vertcat(yParts{:});
end

function values = axisLimits(data, stored)
data = finiteReal(data);
values = finitePair(stored);
if ~isempty(values), return; end
if isempty(data)
    values = [-1 1];
    return;
end
minimum = min(data);
maximum = max(data);
span = maximum - minimum;
if span <= eps(max(1, max(abs([minimum maximum]))))
    span = max(1, abs(minimum));
end
values = [minimum maximum];
if values(1) == values(2)
    values = [minimum - 0.05 * span maximum + 0.05 * span];
end
end

function bounds = numericBounds()
extent = 1e100;
bounds = [-extent extent];
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
