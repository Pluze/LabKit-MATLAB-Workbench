function applicationState = setSource(applicationState, time, force, travel)
%SETSOURCE Initialize independent analysis/reference ranges for a new source.
% Raw overview is bounded for presentation only; calculations read full data.
a=applicationState.session.analysis;
valid=isfinite(time)&isfinite(force)&isfinite(travel);
t=time(valid); f=force(valid); x=travel(valid);
a.sourceRevision=a.resultRevision+1;
a.sourceRange_s=[0 1];
if ~isempty(t), a.sourceRange_s=[min(t) max(t)]; end
a.timeStart_s=a.sourceRange_s(1); a.timeEnd_s=a.sourceRange_s(2);

a.contactTime_s=mean(a.sourceRange_s);
a.contactReview=struct("time_s",[],"force_N",[],"gap_mm",[]); a.lengthFailure="";
display=unique(round(linspace(1,numel(t),min(4000,numel(t)))));
a.overview=struct("time_s",t(display),"force_N",f(display),"gap_mm",x(display));
a.excludedPreview=struct("time_s",[],"force_N",[],"gap_mm",[]);
a.estimate=[]; a.geometryConfirmed=false;
a.lengthEstimateStatus="Enter an approximate contact time; estimate or enter length, then confirm dimensions.";
applicationState.session.analysis=a;
applicationState=mark10_monitor.analysis.invalidate(applicationState,[],[]);
end
