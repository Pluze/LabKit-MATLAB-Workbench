function applicationState = invalidate(applicationState, context, ~)
%INVALIDATE Retire derived curve/fits without redefining initial length.
applicationState = mark10_monitor.analysis.invalidateWindows(applicationState, context, []);
a = applicationState.session.analysis;
a.curve = mark10_monitor.analysis.emptyCurve();
a.curveReady = false;
a.curveRevision = a.resultRevision;
a.status = "Curve needs updating. Review dimensions, then Update Stress-Strain.";
a.exportStatus = "No current stress-strain export.";
applicationState.session.analysis = a;
end
