function result = groupCoordinates(members, xName, yName, unit)
%GROUPCOORDINATES Equal-weight replicate means and sample SD by frequency.
% Presentation/export use complete finite X/Y pairs at each exact frequency.
% Positive unique identical frequency sets are required, in any row order.
% Phase uses circular mean and shortest-angle sample deviations in degrees.
if isempty(members)
    error("eis:EmptyGroup", "A group requires at least one scan.");
end
frequency = members(1).freq_Hz(:);
count = numel(members);
x = NaN(numel(frequency), count);
y = x;
for k = 1:count
    f = members(k).freq_Hz(:);
    if any(~isfinite(f) | f <= 0) || numel(unique(f)) ~= numel(f)
        error("eis:InvalidGroupFrequency", ...
            "Each grouped scan needs unique, finite, positive frequencies.");
    end
    [found, order] = ismember(frequency, f);
    if numel(f) ~= numel(frequency) || ~all(found)
        error("eis:GroupFrequencyMismatch", ...
            "Grouped scans must have exactly the same frequency set; interpolation is not applied.");
    end
    xv = eis.analysisRun.valuesForAxis(members(k), xName, unit);
    yv = eis.analysisRun.valuesForAxis(members(k), yName, unit);
    x(:, k) = xv(order);
    y(:, k) = yv(order);
end
valid = isfinite(x) & isfinite(y);
x(~valid) = NaN;
y(~valid) = NaN;
n = sum(valid, 2);
[xMean, xSD] = moments(x, n, string(xName) == "Zphz (deg)");
[yMean, ySD] = moments(y, n, string(yName) == "Zphz (deg)");
result = struct("frequency", frequency, "x", xMean, "y", yMean, ...
    "xSD", xSD, "ySD", ySD, "n", n);
end

function [average, deviation] = moments(values, n, isPhase)
if isPhase
    sine = mean(sind(values), 2, "omitnan");
    cosine = mean(cosd(values), 2, "omitnan");
    average = atan2d(sine, cosine);
    % Opposing phase vectors have no defined circular direction.
    directionRoundoffTolerance = 10 * eps; % Allow trig/mean roundoff near zero resultant.
    average(hypot(sine, cosine) <= directionRoundoffTolerance) = NaN;
    residual = mod(values - average + 180, 360) - 180;
else
    average = mean(values, 2, "omitnan");
    residual = values - average;
end
deviation = sqrt(sum(residual.^2, 2, "omitnan") ./ (n - 1));
deviation(n < 2 | ~isfinite(average)) = NaN;
end
