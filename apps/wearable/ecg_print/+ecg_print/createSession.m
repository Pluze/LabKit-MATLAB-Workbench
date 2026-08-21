% Rebuild decoded recording, signal products, header preview, workflow log,
% and plot caches from one validated ECG Print project.
function session = createSession(project, ~)
    cache = ecg_print.sourceFiles.emptyCache();
    workflow = struct("importStatus", ...
        "Open a recording to inspect import settings.");
    paths = labkit.app.source.paths(project.inputs.sources);
    filepath = "";
    if ~isempty(paths)
        filepath = paths(1);
    end
    if strlength(filepath) > 0
        [cache, workflow.importStatus] = ...
            ecg_print.sourceFiles.loadRecording( ...
            filepath, project.parameters, project.parameters.channel);
        cache.filePreview = ecg_print.sourceFiles.previewFileHeader( ...
            char(filepath), 18);
        if ~isempty(fieldnames(project.results.lastAnalysis)) && ...
                ~isempty(cache.signal)
            cache = ecg_print.analysisRun.analyzeSignal( ...
                cache, project.parameters);
        end
    end
    session = struct( ...
        "workflow", workflow, ...
        "cache", cache);
end
