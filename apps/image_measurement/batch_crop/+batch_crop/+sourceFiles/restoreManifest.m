% App-owned manifest restore callback. Expected caller: the Images section.
function applicationState = restoreManifest(applicationState, callbackContext)
%RESTOREMANIFEST Replace crop tasks with a validated manifest snapshot.
startPath = applicationState.project.results.resultManifestPath;
if strlength(startPath) == 0
    startPath = applicationState.project.parameters.outputFolder;
end
choice = callbackContext.chooseInputFile( ...
    {"*.csv", "Batch Crop manifest (*.csv)"}, startPath);
if choice.Cancelled
    return
end
try
    plan = batch_crop.resultFiles.readManifest(choice.Value);
    candidate = applicationState;
    sources = repmat(applicationState.project.inputs.sources, 0, 1);
    for index = 1:numel(plan.paths)
        sources(index, 1) = labkit.app.source.record( ...
            plan.tasks(index).sourceId, "cropSource", ...
            plan.paths(index));
    end
    candidate.project.inputs.sources = sources;
    candidate.project.inputs.items = plan.tasks;
    names = string(fieldnames(plan.parameters));
    for name = names.'
        candidate.project.parameters.(char(name)) = ...
            plan.parameters.(char(name));
    end
    candidate.project.results = batch_crop.resultFiles.clearExportState( ...
        candidate.project.results);
    candidate.session = batch_crop.createSession( ...
        candidate.project, callbackContext);
    candidate.session.selection.currentIndex = 1;
    candidate.session.workflow.cropDefaultsInitialized = true;
    applicationState = candidate;
    callbackContext.log("info", ...
        "batch_crop.sourcefiles.restoremanifest.completed", ...
        "Restored " + string(numel(plan.tasks)) + ...
        " crop task(s) from manifest.");
catch cause
    callbackContext.log("error", ...
        "batch_crop.sourcefiles.restoremanifest.exception", ...
        "Could not restore the Batch Crop manifest.", ...
        Category="failure", Audience="developer", Exception=cause);
    callbackContext.alert(cause.message, "Could not restore manifest");
end
end
