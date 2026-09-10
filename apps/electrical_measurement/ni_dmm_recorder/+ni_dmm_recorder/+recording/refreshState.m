function applicationState = refreshState(applicationState, context)
%REFRESHSTATE Copy one bounded NI-DMM buffer snapshot into visible state.
buffer = context.getResource("nidmmBuffer");
buffer("refreshPending") = false;
a = applicationState.session.acquisition;
a.sampleCount = buffer("sampleCount");
a.validCount = buffer("validCount");
a.invalidCount = buffer("invalidCount");
a.elapsed_s = buffer("lastElapsed_s");
a.value = buffer("lastValue");
a.unit = buffer("lastUnit");
a.plotTime_s = buffer("plotTime_s");
a.plotValue = buffer("plotValue");
a.plotTimestampUTC = buffer("plotTimestampUTC");
if a.elapsed_s > 0
    a.actualRate_Hz = a.sampleCount / a.elapsed_s;
else
    a.actualRate_Hz = 0;
end
applicationState.session.acquisition = a;
applicationState.session.connection.lastFailure = buffer("lastFailure");
end
