function applicationState = settingsChanged(applicationState, ~, ~)
%SETTINGSCHANGED Keep the applied snapshot visible until Analyze is selected.
signal = applicationState.session.cache.signal;
if ~isempty(signal)
    last = signal.time(end);
    p = applicationState.project.parameters;
    p.roiStart = min(max(0,p.roiStart),max(0,last-1/signal.fs));
    p.roiEnd = min(last,max(p.roiStart+1/signal.fs,p.roiEnd));
    applicationState.project.parameters = p;
end
applicationState.session.analysisStatus = "Settings changed. Select Analyze to apply.";
end
