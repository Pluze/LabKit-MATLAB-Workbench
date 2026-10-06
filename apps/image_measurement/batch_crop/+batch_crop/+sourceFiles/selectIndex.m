function applicationState = selectIndex( ...
        applicationState, index, callbackContext)
items = applicationState.project.inputs.items;
if isempty(items)
    applicationState.session.selection.currentIndex = 0;
    return
end
applicationState.session.selection.currentIndex = ...
    min(max(round(double(index)), 1), numel(items));
applicationState.session.workflow.scaleReferenceEditing = false;
applicationState.session.view.scaleBar = [];
[applicationState, loaded] = batch_crop.sourceFiles.loadCurrent( ...
    applicationState, callbackContext);
if loaded
    applicationState = batch_crop.cropGeometry.ensureCurrentCenter( ...
        applicationState);
end
end
