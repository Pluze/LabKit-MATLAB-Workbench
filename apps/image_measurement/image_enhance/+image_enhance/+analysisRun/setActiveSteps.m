% Replace the shared or selected per-image enhancement history in App state.
function state = setActiveSteps(state, steps)
    if state.project.parameters.batchMode
        state.project.annotations.sharedSteps = steps;
        return;
    end
    index = state.session.selection.currentIndex;
    sources = state.project.inputs.sources;
    if index < 1 || index > numel(sources)
        return;
    end
    annotation = image_enhance.sourceLibrary.annotationForSource( ...
        state.project.annotations.items, sources(index).id);
    annotation.steps = steps;
    state.project.annotations.items = ...
        image_enhance.sourceLibrary.storeAnnotation( ...
            state.project.annotations.items, annotation);
end
