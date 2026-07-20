function view = present(state)
%PRESENT Map Focus Stack state to a complete semantic workbench snapshot.
hasStack = numel(state.session.cache.images) >= 2;
view = labkit.app.view.Snapshot();
view = view.enabled("runFocusStack", hasStack);
view = view.value("sourceLocation", sourceDescription( ...
    state.session.cache.sourcePaths));
view = view.include(focus_stack.focusPreview.present(state));
end

function text = sourceDescription(paths)
if isempty(paths)
    text = "No images loaded";
    return;
end
text = "Selected image files from " + ...
    string(fileparts(string(paths(1))));
end
