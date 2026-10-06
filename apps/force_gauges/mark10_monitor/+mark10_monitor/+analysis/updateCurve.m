function applicationState = updateCurve(applicationState, context)
%UPDATECURVE Explicit full-resolution calculation independent of modulus fits.
try
    [t,f,x] = mark10_monitor.analysis.sourceData(applicationState,context);
    curve = mark10_monitor.analysis.prepareCurve(t,f,x,applicationState.session.analysis, ...
        applicationState.session.experiment.type);
catch cause
    applicationState=mark10_monitor.analysis.invalidate(applicationState,context,[]);
    applicationState.session.analysis.status="Curve unavailable: "+string(cause.message);
    context.log("error","analysis.curve_failed","Could not prepare stress-strain data.",Exception=cause);
    context.alert(cause.message,"Stress-Strain Analysis");
    return;
end
applicationState = mark10_monitor.analysis.invalidateWindows(applicationState,context,[]);
applicationState.session.analysis.curve=curve;
applicationState.session.analysis.curveReady=true;
applicationState.session.analysis.curveRevision=applicationState.session.analysis.resultRevision;
applicationState.session.analysis.status=compose("Curve ready: %d samples; %d excluded. Add windows or export stress-strain.",numel(curve.time_s),curve.excludedCount);
end
