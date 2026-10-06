function applicationState = openDiagnostics(applicationState, ~)
%OPENDIAGNOSTICS Request the framework-owned live diagnostic plot window.
applicationState.session.analysis.diagnosticRequest=applicationState.session.analysis.diagnosticRequest+1;
end
