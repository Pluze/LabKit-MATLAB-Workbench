function applicationState = selectionChanged( ...
        applicationState, selection, callbackContext)
%SELECTIONCHANGED Reconcile durable crop tasks after source-list changes.
sources = applicationState.project.inputs.sources;
items = applicationState.project.inputs.items;
wasEmpty = isempty(items);
sourceIds = string({sources.id});
if isempty(items)
    retained = items;
else
    retained = items(ismember(string({items.sourceId}), sourceIds));
end
for k = 1:numel(sourceIds)
    if ~any(string({retained.sourceId}) == sourceIds(k))
        task = batch_crop.cropTasks.emptyTask();
        task.sourceId = sourceIds(k);
        retained(end + 1, 1) = task;
    end
end
applicationState.project.inputs.items = retained;
applicationState.project.results = ...
    batch_crop.resultFiles.clearExportState(applicationState.project.results);
if strlength(applicationState.project.parameters.outputFolder) == 0 && ...
        ~isempty(sources)
    resolved = callbackContext.resolveSourcePaths(sources);
    if ~isempty(resolved) && strlength(resolved(1)) > 0
        applicationState.project.parameters.outputFolder = ...
            string(fullfile(fileparts(resolved(1)), "batch_crop"));
    end
end
applicationState.session = batch_crop.createSession( ...
    applicationState.project, callbackContext);
if wasEmpty
    applicationState.session.workflow.cropDefaultsInitialized = false;
end
if ~isempty(selection.Indices)
    selectedSource = sourceIds(selection.Indices(1));
    match = find(string({retained.sourceId}) == selectedSource, 1);
    if ~isempty(match)
        applicationState.session.selection.currentIndex = match;
    end
end
[applicationState, loaded] = batch_crop.sourceFiles.loadCurrent( ...
    applicationState, callbackContext);
if loaded
    applicationState = batch_crop.cropGeometry.ensureCurrentCenter( ...
        applicationState);
    applicationState = batch_crop.cropGeometry.initializeCropDefaults( ...
        applicationState);
end
callbackContext.appendStatus("Crop tasks: " + string(numel(retained)) + ".");
end
