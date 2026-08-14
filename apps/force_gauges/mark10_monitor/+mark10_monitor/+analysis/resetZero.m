function applicationState = resetZero(applicationState, callbackContext)
%RESETZERO Restore analysis-only force and travel reference levels to zero.
applicationState.session.analysis.forceZero_N = 0;
applicationState.session.analysis.travelZero_mm = 0;
applicationState = mark10_monitor.analysis.invalidate( ...
    applicationState, callbackContext, []);
applicationState.session.analysis.status = ...
    "Analysis force and travel zero levels reset to 0.";
end
