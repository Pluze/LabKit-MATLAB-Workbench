function applicationState = resetImport( ...
        applicationState, ~, ~)
%RESETIMPORT Mark decoded analysis stale after an import option changes.
applicationState.project.results.lastAnalysis = struct();
applicationState.project.results.lastSegmentExport = [];
applicationState.project.results.lastWaveformExport = [];
applicationState.session.cache.filteredSignal = [];
applicationState.session.cache.events = [];
applicationState.session.cache.segments = [];
applicationState.session.cache.template = [];
applicationState.session.cache.measurements = [];
if ~isempty(applicationState.session.cache.signal)
    applicationState.session.cache.workingSignal = ...
        applicationState.session.cache.signal;
end
if ~isempty(applicationState.project.inputs.sources)
    applicationState.session.workflow.importStatus = ...
        "Import settings changed. Click Parse / refresh file.";
end
end
