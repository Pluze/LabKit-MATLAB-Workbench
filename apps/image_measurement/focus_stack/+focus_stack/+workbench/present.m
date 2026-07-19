function view = present(state)
%PRESENT Map Focus Stack state to a complete semantic workbench snapshot.
hasStack = numel(state.session.cache.images) >= 2;
view = labkit.app.view.Snapshot();
view = view.enabled("runFocusStack", hasStack);
view = view.include(focus_stack.focusPreview.present(state));
end
