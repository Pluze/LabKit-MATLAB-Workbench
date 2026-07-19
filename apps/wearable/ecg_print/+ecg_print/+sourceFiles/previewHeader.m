function state = previewHeader(state, context)
paths = context.resolveSourcePaths(state.project.inputs.sources, "recording");
if strlength(paths(1)) > 0, state.session.cache.filePreview = ecg_print.sourceFiles.previewFileHeader(paths(1), 18); end
end
