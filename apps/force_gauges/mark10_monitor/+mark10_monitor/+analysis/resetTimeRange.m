function applicationState = resetTimeRange(applicationState, context)
%RESETTIMERANGE Restore complete source times without changing the reference.
a=applicationState.session.analysis;
a.timeStart_s=a.sourceRange_s(1); a.timeEnd_s=a.sourceRange_s(2);
applicationState.session.analysis=a;
applicationState=mark10_monitor.analysis.invalidate(applicationState,context,[]);
end
