function state = refreshImport(state, context)
paths = context.resolveSourcePaths(state.project.inputs.sources);
if strlength(paths(1)) == 0, context.alert("Open a recording before parsing.", "No recording selected"); return; end
[cache, status] = ecg_print.sourceFiles.loadRecording(paths(1), state.project.parameters, state.project.parameters.channel);
cache.filePreview = ecg_print.sourceFiles.previewFileHeader(paths(1), 18);
state.session.cache = cache; state.session.workflow.importStatus = status;
if ~isempty(cache.signal), state.project.parameters.channel = string(cache.signal.displayName); state.project.parameters.roiStart = 0; state.project.parameters.roiEnd = max(cache.signal.time); end
end
