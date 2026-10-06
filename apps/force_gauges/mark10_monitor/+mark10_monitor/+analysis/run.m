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
a.status=compose("%d branch-window results.",size(result.rows,1));
if applicationState.session.experiment.type~="Cyclic"
    a.status=compose("%d window results from one segment.",size(result.rows,1));
    if ~isempty(result.rows)
        times=a.curve.time_s(a.curve.segment==result.rows{1,1});
        a.status=a.status+compose(" Used %.6g–%.6g s; adjust analysis time bounds to choose another segment.",times(1),times(end));
    end
end
a.status=a.status+" Low R2, partial coverage and negative slopes remain visible.";
applicationState.session.analysis=a;
end
