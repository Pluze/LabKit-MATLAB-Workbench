function applicationState = deleteWindow(applicationState, context)
%DELETEWINDOW Remove the selected editable region.
a=applicationState.session.analysis;
if a.selectedWindow>=1 && a.selectedWindow<=size(a.windows,1)
    a.windows(a.selectedWindow,:)=[];
end
a.selectedWindow=min(a.selectedWindow,size(a.windows,1));
applicationState.session.analysis=a;
applicationState=mark10_monitor.analysis.invalidateWindows(applicationState,context,[]);
end
