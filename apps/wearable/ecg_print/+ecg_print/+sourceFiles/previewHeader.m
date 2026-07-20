function applicationState = previewHeader(applicationState, callbackContext)
%PREVIEWHEADER Read the first lines of the selected text recording.
paths = callbackContext.resolveSourcePaths( ...
    applicationState.project.inputs.sources);
if isempty(paths) || strlength(paths(1)) == 0
    applicationState.session.cache.filePreview = { ...
        'Open a CSV/text file, then use Preview file header.'};
    return;
end
applicationState.session.cache.filePreview = ...
    ecg_print.sourceFiles.previewFileHeader(paths(1), 18);
callbackContext.appendStatus("Previewed file header: " + paths(1));
end
