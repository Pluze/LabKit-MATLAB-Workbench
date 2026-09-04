% App-owned implementation for ecg_print.sourceFiles.resetImport within the ecg_print product workflow.
function applicationState = resetImport( ...
        applicationState, ~, ~)
%RESETIMPORT Mark decoded analysis stale after an import option changes.
applicationState.project.results.lastAnalysis = struct();
applicationState.project.results.lastSegmentExport = [];
applicationState.project.results.lastWaveformExport = [];
applicationState.session.cache.filteredSignal = [];
applicationState.session.cache.peakDetectionSignal = [];
applicationState.session.cache.events = [];
applicationState.session.cache.segments = [];
applicationState.session.cache.template = [];
applicationState.session.cache.measurements = [];
applicationState.session.cache.filterDetails = [];
applicationState.session.cache.powerSpectra = [];
if ~isempty(applicationState.session.cache.signal)
    applicationState.session.cache.workingSignal = ...
        applicationState.session.cache.signal;
end
if ~isempty(applicationState.project.inputs.sources)
    applicationState.session.workflow.importStatus = ...
        "Import settings changed. Click Parse / refresh file.";
end
end
