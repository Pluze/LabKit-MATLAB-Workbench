function applicationState = resetZero(applicationState, callbackContext)
%RESETZERO Restore plot and analysis force/travel reference levels to zero.
applicationState.session.analysis.forceZeroDraft_N = 0;
applicationState.session.analysis.travelZeroDraft_mm = 0;
applicationState.session.analysis.forceZero_N = 0;
applicationState.session.analysis.travelZero_mm = 0;
applicationState = mark10_monitor.analysis.applyZero( ...
    applicationState, callbackContext);
applicationState.session.analysis.status = ...
    "Plot force and travel zero levels reset to 0.";
end
