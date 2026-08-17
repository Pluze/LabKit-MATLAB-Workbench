function [force_N, travel_mm] = shiftPlotData(force_N, travel_mm, analysis)
%SHIFTPLOTDATA Apply the shared force and travel plot baselines.
[forceZero_N, travelZero_mm] = ...
    mark10_monitor.analysis.appliedZeroLevels(analysis);
force_N = double(force_N) - forceZero_N;
travel_mm = double(travel_mm) - travelZero_mm;
end
