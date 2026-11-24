function [excluded, forceOutlier, travelOutlier] = detectGlitches(force_N, travel_mm)
%DETECTGLITCHES Flag isolated excursions that immediately return to trend.
forceOutlier = isolated(double(force_N(:)));
travelOutlier = isolated(double(travel_mm(:)));
excluded = travelOutlier;
if ~isempty(forceOutlier)
    excluded = forceOutlier | travelOutlier;
end
end

function flagged = isolated(values)
flagged = false(size(values));
halfWindow = 5;
centres = (halfWindow+1:numel(values)-halfWindow).';
if isempty(centres), return; end

% Estimate the local first difference without either edge of the candidate.
% Opposing residuals distinguish a returning spike from a persistent step.
steps = diff(values);
neighbours = steps(centres + [-halfWindow:-2, 1:halfWindow-1]);
slope = median(neighbours, 2);
noise = 1.4826 * median(abs(neighbours-slope), 2);
tick = mark10_monitor.analysis.observedIncrement(values);
noiseMultiplier = 8;
tickMultiplier = 2; % Allow a one-count change and rounding on both edges.
threshold = max(noiseMultiplier*noise, tickMultiplier*tick);
incoming = steps(centres-1)-slope;
outgoing = steps(centres)-slope;
% After dropping the candidate, its two neighbors must agree with the trend.
returnsToTrend = abs(incoming+outgoing) <= threshold;
flagged(centres) = returnsToTrend & sign(incoming) ~= sign(outgoing) & ...
    min(abs(incoming),abs(outgoing)) > threshold;
end
