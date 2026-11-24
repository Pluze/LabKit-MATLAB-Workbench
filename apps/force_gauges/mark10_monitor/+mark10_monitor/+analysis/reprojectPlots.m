function applicationState = reprojectPlots(applicationState, context)
%REPROJECTPLOTS Apply current plot settings to the current source and viewport.
if applicationState.session.playback.loaded && ...
        applicationState.session.analysis.dataSource == "Loaded Recording"
    playback = context.getResource("mark10Playback");
    applicationState = mark10_monitor.playback.applyCursor( ...
        applicationState,playback,applicationState.session.playback.cursor,true);
else
    buffer = context.getResource("mark10Buffer");
    analysis = applicationState.session.analysis;
    valid = buffer("valid");
    t = buffer("time_s"); f = buffer("force_N"); x = buffer("travel_mm");
    analysis.travelProfile = mark10_monitor.analysis.travelProfile( ...
        t(valid),f(valid),x(valid),analysis.travel, ...
        applicationState.session.acquisition.monitoring,applicationState.session.experiment.type);
    acquisition = applicationState.session.acquisition;
    acquisition.plotTime_s = buffer("plotTime_s");
    [acquisition.plotForce_N, acquisition.plotTravel_mm, acquisition.plotReconstructed_mm] = ...
        mark10_monitor.analysis.plotCoordinates(acquisition.plotTime_s, ...
        buffer("plotForce_N"),buffer("plotTravel_mm"),analysis);
    applicationState.session.acquisition = acquisition;
    applicationState.session.analysis = analysis;
end
applicationState = mark10_monitor.livePlots.updateLimits(applicationState,true);
end
