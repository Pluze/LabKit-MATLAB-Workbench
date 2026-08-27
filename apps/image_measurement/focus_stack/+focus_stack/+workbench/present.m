% App-owned implementation for focus_stack.workbench.present within the focus_stack product workflow.
function view = present(state)
%PRESENT Map Focus Stack state to a complete semantic workbench snapshot.
cache = state.session.cache;
project = state.project;
hasStack = numel(cache.images) >= 2;
viewRevision = focus_stack.focusPreview.viewportRevision( ...
    project.inputs.sources, cache.result.ok, cache.plotViewRevision);
view = labkit.app.view.Snapshot();
view = view.enabled("runFocusStack", hasStack);
view = view.value("sourceLocation", sourceDescription( ...
    cache.sourcePaths));
view = view.include(focus_stack.focusPreview.present( ...
    cache, project.results, numel(project.inputs.sources), viewRevision));
end

function text = sourceDescription(paths)
if isempty(paths)
    text = "No images loaded";
    return;
end
text = "Selected image files from " + ...
    string(fileparts(string(paths(1))));
end
