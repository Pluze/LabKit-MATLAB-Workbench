function applicationState = duplicateCurrent(applicationState, callbackContext)
[applicationState, loaded] = batch_crop.sourceFiles.loadCurrent( ...
    applicationState, callbackContext);
if ~loaded
    return
end
index = batch_crop.sourceFiles.currentIndex(applicationState);
duplicate = batch_crop.cropTasks.duplicateItem( ...
    applicationState.project.inputs.items(index));
items = applicationState.project.inputs.items;
applicationState.project.inputs.items = ...
    [items(1:index); duplicate; items(index + 1:end)];
images = applicationState.session.cache.images;
applicationState.session.cache.images = ...
    [images(1:index); images(index); images(index + 1:end)];
paths = applicationState.session.cache.paths;
applicationState.session.cache.paths = ...
    [paths(1:index); paths(index); paths(index + 1:end)];
applicationState.session.selection.currentIndex = index + 1;
applicationState = batch_crop.cropGeometry.ensureCurrentCenter( ...
    applicationState);
applicationState = batch_crop.cropGeometry.clearDerived(applicationState, true);
callbackContext.appendStatus( ...
    "Duplicated crop task " + string(index) + ".");
end
