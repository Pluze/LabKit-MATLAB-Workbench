function applicationState = chooseFolder(applicationState, callbackContext)
%CHOOSEFOLDER Replace the current stack with supported images from a folder.
startPath = applicationState.project.parameters.outputFolder;
if strlength(startPath) == 0 && ...
        ~isempty(applicationState.session.cache.sourcePaths)
    startPath = string(fileparts( ...
        applicationState.session.cache.sourcePaths(1)));
end
choice = callbackContext.chooseInputFolder(startPath);
if choice.Cancelled
    callbackContext.appendStatus( ...
        "Focus image folder selection cancelled.");
    return;
end
folder = string(choice.Value);
try
    paths = focus_stack.sourceFiles.findImages(folder);
    images = focus_stack.sourceFiles.readImages(paths);
catch ME
    callbackContext.reportError("Load focus image folder", ME);
    callbackContext.alert(ME.message, "Could not load focus image folder");
    callbackContext.appendStatus( ...
        "Could not load focus image folder: " + string(ME.message));
    return;
end
incoming = labkit.app.project.emptySourceRecords();
for index = 1:numel(paths)
    record = labkit.app.project.sourceRecord( ...
        "image_" + compose("%03d", index), ...
        "focus-image", paths(index), true);
    incoming(end + 1, 1) = record;
end
applicationState.project.inputs.sources = incoming;
applicationState = focus_stack.analysisRun.invalidate( ...
    applicationState, [], callbackContext);
applicationState.project.parameters.outputFolder = folder;
applicationState.session.cache.images = images;
applicationState.session.cache.alignedImages = {};
applicationState.session.cache.result = ...
    focus_stack.analysisRun.emptyResult();
applicationState.session.cache.sourcePaths = paths;
ids = string({applicationState.project.inputs.sources.id});
applicationState.session.selection.sourceImages = ...
    labkit.app.event.ListSelection( ...
        Ids=ids, Indices=1:numel(ids));
callbackContext.appendStatus(sprintf( ...
    "Loaded %d focus image file(s) from folder.", numel(paths)));
end
