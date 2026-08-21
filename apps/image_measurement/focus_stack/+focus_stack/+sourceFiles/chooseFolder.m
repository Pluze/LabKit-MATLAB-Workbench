% App-owned implementation for focus_stack.sourceFiles.chooseFolder within the focus_stack product workflow.
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
    callbackContext.log("info", ...
        "focus_stack.sourcefiles.choosefolder.cancelled", ...
        "Focus image folder selection cancelled.");
    return;
end
folder = string(choice.Value);
try
    paths = focus_stack.sourceFiles.findImages(folder);
    images = focus_stack.sourceFiles.readImages(paths);
catch ME
    callbackContext.log("error", "focus_stack.sourcefiles.choosefolder.exception", "Load focus image folder", ...
        Category="failure", Audience="developer", Exception=ME);
    callbackContext.alert(ME.message, "Could not load focus image folder");
    callbackContext.log("error", ...
        "focus_stack.sourcefiles.choosefolder.failed", ...
        "Could not load the focus image folder.");
    return;
end
incoming = repmat(labkit.app.source.record( ...
    "placeholder", "focus-image", "", true), numel(paths), 1);
for index = 1:numel(paths)
    record = labkit.app.source.record( ...
        "image_" + compose("%03d", index), ...
        "focus-image", paths(index), true);
    incoming(index, 1) = record;
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
callbackContext.log("info", ...
    "focus_stack.sourcefiles.choosefolder.completed", sprintf( ...
    "Loaded %d focus image file(s) from folder.", numel(paths)));
end
