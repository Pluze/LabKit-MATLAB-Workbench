function applicationState = applyZero(applicationState, callbackContext)
%APPLYZERO Commit draft zero levels and reproject both live plots.
analysis = applicationState.session.analysis;
forceZero_N = draftValue(analysis, "forceZeroDraft_N", "forceZero_N");
travelZero_mm = draftValue( ...
    analysis, "travelZeroDraft_mm", "travelZero_mm");
applicationState.session.analysis.forceZeroDraft_N = forceZero_N;
applicationState.session.analysis.travelZeroDraft_mm = travelZero_mm;
applicationState.session.analysis.forceZero_N = forceZero_N;
applicationState.session.analysis.travelZero_mm = travelZero_mm;
applicationState = mark10_monitor.analysis.invalidateReference( ...
    applicationState, callbackContext, []);
applicationState = mark10_monitor.analysis.reprojectPlots(applicationState, callbackContext);
applicationState.session.analysis.status = compose( ...
    "Applied plot zero: force %.6g N, travel %.6g mm.", ...
    forceZero_N, travelZero_mm);
end

function value = draftValue(analysis, draftName, appliedName)
value = 0;
if isfield(analysis, appliedName)
    value = analysis.(appliedName);
end
if isfield(analysis, draftName)
    value = analysis.(draftName);
end
value = double(value);
if ~isscalar(value) || ~isfinite(value)
    error("mark10_monitor:analysis:InvalidZeroLevel", ...
        "%s must be a finite scalar.", draftName);
end
end
