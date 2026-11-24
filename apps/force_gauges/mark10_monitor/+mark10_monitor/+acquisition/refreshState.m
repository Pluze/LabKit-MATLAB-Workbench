function state = refreshState(state, context)
%REFRESHSTATE Copy one bounded resource snapshot into visible session state.
buffer = context.getResource("mark10Buffer");
buffer("refreshPending") = false;
if ~state.session.connection.connected
    return;
end
connectionBox = context.getResource("mark10Connection");
connection = connectionBox("connection");
a = state.session.acquisition;
a.sampleCount = buffer("sampleCount");
a.validCount = buffer("validCount");
a.invalidCount = buffer("invalidCount");
a.retainedValidCount = sum(buffer("valid"));
a.elapsed_s = buffer("lastTime_s");
a.force_N = buffer("lastForce_N");
a.travel_mm = buffer("lastTravel_mm");
a.plotTime_s = buffer("plotTime_s");
analysis = state.session.analysis;
if a.elapsed_s-analysis.travelUpdated_s>=0.5 && ...
        (analysis.travel.mode~="Measured gap" || analysis.travel.contact_s>=0)
    % Refit the stroke twice per second while rendering samples at up to 10 Hz.
    valid = buffer("valid");
    t = buffer("time_s"); f = buffer("force_N"); x = buffer("travel_mm");
    analysis.travelProfile = mark10_monitor.analysis.travelProfile( ...
        t(valid),f(valid),x(valid),analysis.travel,a.monitoring,state.session.experiment.type);
    analysis.travelUpdated_s = a.elapsed_s;
    state.session.analysis = analysis;
end
[a.plotForce_N, a.plotTravel_mm, a.plotReconstructed_mm] = mark10_monitor.analysis.plotCoordinates( ...
    a.plotTime_s,buffer("plotForce_N"),buffer("plotTravel_mm"),analysis);
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
