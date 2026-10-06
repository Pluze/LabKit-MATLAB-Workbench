function applicationState = addWindow(applicationState, context)
%ADDWINDOW Append an editable region without changing the curve.
a=applicationState.session.analysis;
lo=0; hi=10;
if ~isempty(a.windows), lo=a.windows{end,4}; hi=lo+10; end
a.windows(end+1,:)={true,char("Region "+string(size(a.windows,1)+1)),lo,hi};
a.selectedWindow=size(a.windows,1);
applicationState.session.analysis=a;
applicationState=mark10_monitor.analysis.invalidateWindows(applicationState,context,[]);
end
