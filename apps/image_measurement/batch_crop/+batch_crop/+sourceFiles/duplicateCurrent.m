% App-owned implementation for batch_crop.sourceFiles.duplicateCurrent within the batch_crop product workflow.
function applicationState = duplicateCurrent(applicationState, callbackContext)
[applicationState, loaded] = batch_crop.sourceFiles.loadCurrent( ...
    applicationState, callbackContext);
if ~loaded
    return
end
index = batch_crop.sourceFiles.currentIndex(applicationState);
items = reshape(applicationState.project.inputs.items, [], 1);
sources = reshape(applicationState.project.inputs.sources, [], 1);
images = reshape(applicationState.session.cache.images, [], 1);
paths = string(applicationState.session.cache.paths);
paths = paths(:);
duplicate = batch_crop.cropTasks.duplicateItem( ...
    items(index));
path = paths(index);
sourceId = nextSourceId(sources);
source = labkit.app.project.sourceRecord( ...
    sourceId, "cropSource", path, true);
duplicate.sourceId = sourceId;
applicationState.project.inputs.items = ...
    [items(1:index); duplicate; items(index + 1:end)];
applicationState.project.inputs.sources = ...
    [sources(1:index); source; sources(index + 1:end)];
applicationState.session.cache.images = ...
    [images(1:index); images(index); images(index + 1:end)];
applicationState.session.cache.paths = ...
    [paths(1:index); paths(index); paths(index + 1:end)];
applicationState.session.selection.currentIndex = index + 1;
applicationState = batch_crop.cropGeometry.ensureCurrentCenter( ...
    applicationState);
applicationState = batch_crop.cropGeometry.clearDerived(applicationState, true);
callbackContext.log("info", ...
    "batch_crop.sourcefiles.duplicatecurrent.completed", ...
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
