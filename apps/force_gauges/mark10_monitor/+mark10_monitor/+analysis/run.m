function applicationState = run(applicationState, context)
%RUN Compute every enabled window; low linearity never hides a result.
if ~applicationState.session.analysis.curveReady
    applicationState=mark10_monitor.analysis.updateCurve(applicationState,context);
end
if ~applicationState.session.analysis.curveReady, return; end
a=applicationState.session.analysis;
try
    result=mark10_monitor.analysis.fitWindows(a.curve,a.windows,applicationState.session.experiment.type);
catch cause
    context.log("error","analysis.fit_failed","Could not fit strain windows.",Exception=cause);
    context.alert(cause.message,"Strain Windows");
    return;
end
a.resultRows=result.rows; a.fitLines=result.fitLines;
a.selectedResult=double(~isempty(result.rows));
a.resultRevision=a.resultRevision+1;
a.status=compose("%d branch-window results. Low R2, partial coverage and negative slopes remain visible.",size(result.rows,1));
applicationState.session.analysis=a;
end
