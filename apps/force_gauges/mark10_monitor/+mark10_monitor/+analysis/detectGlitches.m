function [excluded, forceOutlier, travelOutlier] = detectGlitches(force_N, travel_mm)
%DETECTGLITCHES Flag isolated excursions with a return to the local trend.
% Five samples on each side define the local median and robust noise scale.
% Two-sided agreement protects persistent steps such as fracture or unloading.
% Minimum jumps of 0.02 N and 0.02 mm protect small quantization changes;
% these are analysis heuristics, not instrument calibration.
minimumForceJump_N = 0.02;
minimumTravelJump_mm = 0.02;
forceOutlier = isolated(double(force_N(:)), minimumForceJump_N);
travelOutlier = isolated(double(travel_mm(:)), minimumTravelJump_mm);
excluded = forceOutlier | travelOutlier;
end

function flagged = isolated(values, minimumJump)
flagged = false(size(values));
halfWindow = 5;
noiseMultiplier = 8;
normalMadScale = 1.4826;
for index = halfWindow+1:numel(values)-halfWindow
    before = values(index-halfWindow:index-1);
    after = values(index+1:index+halfWindow);
    neighbours = [before; after];
    centre = median(neighbours);
    noise = normalMadScale * median(abs(neighbours - centre));
    threshold = max(minimumJump, noiseMultiplier * noise);
    returnsToTrend = abs(median(before) - median(after)) <= threshold;
    flagged(index) = returnsToTrend && abs(values(index) - centre) > threshold;
end
end
