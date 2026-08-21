% App-owned implementation for ecg_print.sourceFiles.refreshImport within the ecg_print product workflow.
function applicationState = refreshImport(applicationState, callbackContext)
%REFRESHIMPORT Reparse the selected recording with current import settings.
paths = labkit.app.source.paths( ...
    applicationState.project.inputs.sources);
if isempty(paths) || strlength(paths(1)) == 0
    callbackContext.alert( ...
        "Open a recording before parsing.", "No recording selected");
    return;
end
filepath = paths(1);
preview = ecg_print.sourceFiles.previewFileHeader(filepath, 18);
try
    [cache, status] = ecg_print.sourceFiles.loadRecording( ...
        filepath, applicationState.project.parameters, ...
        applicationState.project.parameters.channel);
catch cause
    callbackContext.log("error", "ecg_print.sourcefiles.refreshimport.exception", "Recording parse failed", ...
        Category="failure", Audience="developer", Exception=cause);
    cache = ecg_print.sourceFiles.emptyCache();
    cache.filepath = filepath;
    cache.filePreview = preview;
    applicationState.session.cache = cache;
    applicationState.session.workflow.importStatus = ...
        "Parse failed. Inspect header/settings, then refresh: " + ...
        cause.message;
    applicationState.project.parameters.channel = "(none)";
    applicationState.project.results.lastAnalysis = struct();
    applicationState.project.results.lastSegmentExport = [];
    applicationState.project.results.lastWaveformExport = [];
    callbackContext.log("error", "ecg_print.sourcefiles.refreshimport.failed", ...
        "Recording import failed.");
    callbackContext.alert(cause.message, "Could not parse recording");
    return;
end
cache.filePreview = preview;
applicationState.session.cache = cache;
applicationState.session.workflow.importStatus = status;
applicationState.project.parameters.channel = string( ...
    cache.signal.displayName);
applicationState.project.parameters.roiStart = 0;
applicationState.project.parameters.roiEnd = max(cache.signal.time);
applicationState.project.results.lastAnalysis = struct();
applicationState.project.results.lastSegmentExport = [];
applicationState.project.results.lastWaveformExport = [];
callbackContext.log("info", "ecg_print.sourcefiles.refreshimport.completed", sprintf( ...
    "Imported %d recording channel(s).", numel(cache.channelItems)));
end
