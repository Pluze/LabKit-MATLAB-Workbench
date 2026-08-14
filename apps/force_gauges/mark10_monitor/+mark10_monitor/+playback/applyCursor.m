function state = applyCursor(state, playback, index)
%APPLYCURSOR Copy the complete replay prefix into visible session state.
count = numel(playback("time_s"));
index = min(max(0, round(index)), count);
indices = 1:index;
if index == 0, indices = zeros(1, 0); end
a = state.session.acquisition;
time = playback("time_s");
force = playback("force_N");
travel = playback("travel_mm");
a.plotTime_s = time(indices);
[a.plotForce_N, a.plotTravel_mm] = ...
    mark10_monitor.analysis.shiftPlotData( ...
    force(indices), travel(indices), state.session.analysis, 0);
a.sampleCount = index;
a.validCount = index;
a.invalidCount = 0;
a.actualRate_Hz = 0;
if index > 0
    a.elapsed_s = time(index);
    a.force_N = force(index);
    a.travel_mm = travel(index);
    if a.elapsed_s > 0, a.actualRate_Hz = index / a.elapsed_s; end
else
    a.elapsed_s = 0;
    a.force_N = NaN;
    a.travel_mm = NaN;
end
state.session.acquisition = a;
state.session.playback.cursor = index;
state.session.playback.count = count;
state = mark10_monitor.livePlots.updateLimits(state, false);
end
