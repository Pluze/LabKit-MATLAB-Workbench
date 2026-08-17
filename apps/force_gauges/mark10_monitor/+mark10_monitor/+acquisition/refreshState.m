function state = refreshState(state, context)
%REFRESHSTATE Copy one bounded resource snapshot into visible session state.
buffer = context.getResource("application", "mark10Buffer");
buffer("refreshPending") = false;
if ~state.session.connection.connected
    return;
end
connectionBox = context.getResource("application", "mark10Connection");
connection = connectionBox("connection");
a = state.session.acquisition;
a.sampleCount = buffer("sampleCount");
a.validCount = buffer("validCount");
a.invalidCount = buffer("invalidCount");
a.retainedValidCount = sum(buffer("valid"));
a.elapsed_s = buffer("lastTime_s");
a.force_N = buffer("lastForce_N");
a.travel_mm = buffer("lastTravel_mm") - a.travelZeroOffset_mm;
a.plotTime_s = buffer("plotTime_s");
[a.plotForce_N, a.plotTravel_mm] = ...
    mark10_monitor.analysis.shiftPlotData( ...
    buffer("plotForce_N"), buffer("plotTravel_mm"), ...
    state.session.analysis, a.travelZeroOffset_mm);
if a.elapsed_s > 0
    a.actualRate_Hz = a.sampleCount / a.elapsed_s;
else
    a.actualRate_Hz = 0;
end
state.session.acquisition = a;
state = mark10_monitor.livePlots.updateLimits(state, false);
state.session.connection.acquisitionMode = connection.AcquisitionMode;
state.session.connection.lastFailure = buffer("lastFailure");
end
