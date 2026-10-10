function session = createSession(project, ~)
%CREATESESSION Decode the selected source; analysis runs only on Analyze.
cache = ecg_print.sourceFiles.emptyCache();
status = "Open a recording.";
paths = labkit.app.source.paths(project.inputs.sources);
if ~isempty(paths)
    [cache,status] = ecg_print.sourceFiles.loadRecording( ...
        paths(1),project.parameters,project.parameters.channel);
    cache.filePreview = ecg_print.sourceFiles.previewFileHeader(paths(1),18);
end
session = struct('workflow',struct('importStatus',status), ...
    'cache',cache,'importDirty',false,'debugOverlay',false,'analysisStatus',"Ready to analyze.");
end
