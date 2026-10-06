function applicationState = estimateLength(applicationState, context)
%ESTIMATELENGTH Retain the chosen reference for both success and failure review.
review=struct("time_s",[],"force_N",[],"gap_mm",[]);
try
    [t,f,x]=mark10_monitor.analysis.sourceData(applicationState,context);
    a=applicationState.session.analysis;
    episode=mark10_monitor.analysis.contactEpisode(t,x,a.contactTime_s,applicationState.session.experiment.type);
    selected=find(isfinite(t)&isfinite(f)&isfinite(x)&t>=episode(1)&t<=episode(2));
    selected=selected(unique(round(linspace(1,numel(selected),min(2000,numel(selected))))));
    [f0,x0]=mark10_monitor.analysis.appliedZeroLevels(a);
    review=struct("time_s",t(selected),"force_N",f(selected)-f0,"gap_mm",x(selected)-x0);
    estimate=mark10_monitor.analysis.estimateInitialLength(t,f,x,a,applicationState.session.experiment.type);
catch cause
    applicationState=mark10_monitor.analysis.invalidateReference(applicationState,context,[]);
    guidance="Adjust the approximate contact time to the intended loading approach. The recording must include unloaded baseline and initial loading. Inspect diagnostics or enter measured length.";
    applicationState.session.analysis.contactReview=review;
    applicationState.session.analysis.lengthFailure=string(cause.message)+" "+guidance;
    applicationState.session.analysis.lengthEstimateStatus="Estimate failed. "+string(cause.message)+" "+guidance;
    context.log("error","analysis.length_estimate_failed","Contact estimation failed.",Exception=cause);
    context.alert(string(cause.message)+newline+guidance,"Initial Length Estimation");return;
end
applicationState=mark10_monitor.analysis.invalidate(applicationState,context,[]);
a=applicationState.session.analysis;
a.estimate=estimate;a.contactReview=review;a.lengthFailure="";
a.gaugeLength_mm=estimate.length_mm;a.geometryConfirmed=false;

a.lengthEstimateStatus=compose("%s. Estimated %.6g mm at %.6g s. Local-window range %.6g–%.6g mm (spread %.3g%%, not a confidence interval). %s; R2 %.4g. Review diagnostics, edit if needed, then confirm.", ...
    estimate.quality,estimate.length_mm,estimate.time_s,estimate.lengthRange_mm(1),estimate.lengthRange_mm(2),estimate.spread_percent,estimate.modelName,estimate.rSquared);
applicationState.session.analysis=a;
end
