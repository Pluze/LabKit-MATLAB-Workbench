% Return the shared or selected per-image enhancement history from App state.
function steps = activeSteps(state)
    if state.project.parameters.batchMode
        steps = state.project.annotations.sharedSteps;
        return;
    end
    index = state.session.selection.currentIndex;
    sources = state.project.inputs.sources;
    if index < 1 || index > numel(sources)
        steps = repmat(image_enhance.analysisRun.emptyStep(), 0, 1);
        return;
    end
    annotation = image_enhance.sourceLibrary.annotationForSource( ...
        state.project.annotations.items, sources(index).id);
    steps = annotation.steps;
end
