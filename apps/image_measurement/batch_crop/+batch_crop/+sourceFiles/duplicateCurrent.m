function applicationState = duplicateCurrent(applicationState, callbackContext)
[applicationState, loaded] = batch_crop.sourceFiles.loadCurrent( ...
    applicationState, callbackContext);
if ~loaded
    return
end
index = batch_crop.sourceFiles.currentIndex(applicationState);
duplicate = batch_crop.cropTasks.duplicateItem( ...
    applicationState.project.inputs.items(index));
sources = applicationState.project.inputs.sources;
path = applicationState.session.cache.paths(index);
sourceId = nextSourceId(sources);
source = labkit.app.project.sourceRecord( ...
    sourceId, "cropSource", path, true);
duplicate.sourceId = sourceId;
items = applicationState.project.inputs.items;
applicationState.project.inputs.items = ...
    [items(1:index); duplicate; items(index + 1:end)];
applicationState.project.inputs.sources = ...
    [sources(1:index); source; sources(index + 1:end)];
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

function id = nextSourceId(sources)
ids = string({sources.id});
number = 1;
id = "image-" + string(number);
while any(ids == id)
    number = number + 1;
    id = "image-" + string(number);
end
end
