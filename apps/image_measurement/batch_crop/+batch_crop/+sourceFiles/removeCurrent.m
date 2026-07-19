function applicationState = removeCurrent(applicationState, callbackContext)
index = batch_crop.sourceFiles.currentIndex(applicationState);
items = applicationState.project.inputs.items;
if index < 1 || index > numel(items)
    return
end
items(index) = [];
applicationState.project.inputs.items = items;
applicationState.session.cache.images(index) = [];
applicationState.session.cache.paths(index) = [];
applicationState = batch_crop.cropGeometry.clearDerived(applicationState, true);
applicationState = batch_crop.sourceFiles.selectIndex( ...
    applicationState, min(index, numel(items)), callbackContext);
callbackContext.appendStatus("Removed crop task " + string(index) + ".");
end
