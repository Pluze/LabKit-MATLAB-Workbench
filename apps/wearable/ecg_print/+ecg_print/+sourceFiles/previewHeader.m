% App-owned implementation for ecg_print.sourceFiles.previewHeader within the ecg_print product workflow.
function applicationState = previewHeader(applicationState, callbackContext)
%PREVIEWHEADER Read the first lines of the selected text recording.
paths = labkit.app.source.paths( ...
    applicationState.project.inputs.sources);
if isempty(paths) || strlength(paths(1)) == 0
    applicationState.session.cache.filePreview = { ...
        'Open a CSV/text file, then use Preview file header.'};
    return;
end
applicationState.session.cache.filePreview = ...
    ecg_print.sourceFiles.previewFileHeader(paths(1), 18);
callbackContext.log("info", "ecg_print.sourcefiles.previewheader.completed", ...
    "Previewed the recording header.");
end
