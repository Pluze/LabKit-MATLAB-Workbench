function applicationState = estimateLength(applicationState, context)
%ESTIMATELENGTH Propose an extrapolated length; explicit confirmation required.
try
    [t,f,x]=mark10_monitor.analysis.sourceData(applicationState,context);
    estimate=mark10_monitor.analysis.estimateInitialLength(t,f,x, ...
        applicationState.session.analysis,applicationState.session.experiment.type);
catch cause
    applicationState=mark10_monitor.analysis.invalidateReference(applicationState,context,[]);
    applicationState.session.analysis.lengthEstimateStatus="Estimate failed: "+string(cause.message);
    context.log("error","analysis.length_estimate_failed","Contact extrapolation failed.",Exception=cause);
    context.alert(cause.message,"Initial Length Extrapolation"); return;
end
applicationState=mark10_monitor.analysis.invalidate(applicationState,context,[]);
a=applicationState.session.analysis;
a.estimate=estimate; a.gaugeLength_mm=estimate.length_mm; a.geometryConfirmed=false;
a.lengthEstimateStatus=compose("Zero-force extrapolation: %.6g mm; threshold point: %.6g mm. Fit n=%d, R2=%.4g. Review diagnostics, edit if needed, then confirm dimensions.", ...
    estimate.length_mm,estimate.thresholdLength_mm,estimate.count,estimate.rSquared);
applicationState.session.analysis=a;
end
