%PLANTICKS Resolve locator and formatter state into editable tick rows.
% Inputs are one axis struct containing finite limits, scale, locator, and
% formatter. Output rows retain numeric values separately from display text.
function ticks = planTicks(axisValue)
validateAxis(axisValue);
mode = lower(string(axisValue.locator.mode));
switch mode
    case {"source", "explicit", "category"}
        values = double(axisValue.locator.values(:).');
    case {"auto", "nice-count"}
        values = niceTicks(axisValue.limits, axisValue.locator.count, ...
            axisValue.scale);
    case "fixed-step"
        values = fixedTicks(axisValue.limits, axisValue.locator.step);
    case "log"
        values = logTicks(axisValue.limits);
    otherwise
        error("figure_studio:figureDocument:UnknownTickLocator", ...
            "Unsupported tick locator mode: %s", mode);
end
labels = labelsForValues(values, axisValue.formatter, mode);
ticks = repmat(tickTemplate(), numel(values), 1);
for k = 1:numel(values)
    ticks(k).value = values(k);
    ticks(k).label = labels(k);
end
end

function validateAxis(axisValue)
limits = double(axisValue.limits(:).');
if numel(limits) ~= 2 || any(~isfinite(limits)) || limits(1) >= limits(2)
    error("figure_studio:figureDocument:InvalidAxisLimits", ...
        "Axis limits must be two increasing finite values.");
end
if lower(string(axisValue.scale)) == "log" && limits(1) <= 0
    error("figure_studio:figureDocument:InvalidLogLimits", ...
        "Logarithmic axis limits must be positive.");
end
end

function values = niceTicks(limits, requestedCount, scale)
if lower(string(scale)) == "log"
    values = logTicks(limits);
    return;
end
count = max(2, round(double(requestedCount)));
span = limits(2) - limits(1);
step = niceNumber(span / max(1, count - 1), true);
first = ceil(limits(1) / step) * step;
last = floor(limits(2) / step) * step;
values = first:step:last;
if isempty(values)
    values = limits;
end
values = removeFloatingNoise(values, step);
end

function value = niceNumber(value, roundValue)
exponent = floor(log10(value));
fraction = value / 10^exponent;
if roundValue
    if fraction < 1.5
        niceFraction = 1;
    elseif fraction < 2.25
        niceFraction = 2;
    elseif fraction < 3.5
        niceFraction = 2.5;
    elseif fraction < 7.5
        niceFraction = 5;
    else
        niceFraction = 10;
    end
else
    if fraction <= 1
        niceFraction = 1;
    elseif fraction <= 2
        niceFraction = 2;
    elseif fraction <= 2.5
        niceFraction = 2.5;
    elseif fraction <= 5
        niceFraction = 5;
    else
        niceFraction = 10;
    end
end
value = niceFraction * 10^exponent;
end

function values = fixedTicks(limits, step)
step = double(step);
if ~isscalar(step) || ~isfinite(step) || step <= 0
    error("figure_studio:figureDocument:InvalidTickStep", ...
        "A fixed tick step must be a positive finite scalar.");
end
first = ceil(limits(1) / step) * step;
last = floor(limits(2) / step) * step;
values = removeFloatingNoise(first:step:last, step);
end

function values = logTicks(limits)
first = ceil(log10(limits(1)));
last = floor(log10(limits(2)));
values = 10 .^ (first:last);
if isempty(values)
    values = limits;
end
end

function values = removeFloatingNoise(values, step)
digits = max(0, 2 - floor(log10(abs(step))));
digits = min(15, digits);
scale = 10^digits;
values = round(values .* scale) ./ scale;
end

function labels = labelsForValues(values, formatter, locatorMode)
mode = lower(string(formatter.mode));
sourceLabels = string(fieldValue(formatter, "labels", strings(0, 1)));
if any(mode == ["source", "explicit"]) && ...
        numel(sourceLabels) == numel(values)
    labels = reshape(sourceLabels, 1, []);
    return;
end
precision = fieldValue(formatter, "precision", []);
prefix = string(fieldValue(formatter, "prefix", ""));
suffix = string(fieldValue(formatter, "suffix", ""));
labels = strings(1, numel(values));
for k = 1:numel(values)
    labels(k) = prefix + formatOne(values(k), mode, precision, locatorMode) + suffix;
end
end

function label = formatOne(value, mode, precision, locatorMode)
if isempty(precision)
    precision = 6;
end
precision = max(0, min(15, round(double(precision))));
switch mode
    case "fixed"
        label = string(sprintf("%.*f", precision, value));
    case "scientific"
        label = string(sprintf("%.*e", precision, value));
    case "engineering"
        label = engineeringLabel(value, precision);
    case "percent"
        label = string(sprintf("%.*f%%", precision, 100 * value));
    otherwise
        if locatorMode == "log" && value > 0
            label = "10^{" + string(round(log10(value))) + "}";
        else
            label = string(sprintf("%.15g", value));
        end
end
end

function label = engineeringLabel(value, precision)
if value == 0
    label = "0";
    return;
end
exponent = 3 * floor(log10(abs(value)) / 3);
scaled = value / 10^exponent;
label = string(sprintf("%.*f", precision, scaled)) + "e" + string(exponent);
end

function row = tickTemplate()
row = struct("value", 0, "label", "", "visible", true, ...
    "level", "major", "rotation", 0, "fontOverride", struct());
end

function value = fieldValue(owner, name, fallback)
name = char(name);
if isstruct(owner) && isfield(owner, name)
    value = owner.(name);
else
    value = fallback;
end
end
