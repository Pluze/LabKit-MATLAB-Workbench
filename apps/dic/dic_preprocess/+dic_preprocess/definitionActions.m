% App-owned V2 action registry for DIC Preprocess. Handlers receive
% canonical state/events/services and own image loading, alignment, crop/mask
% annotations, undo history, and exports without raw UI handles.
function actions = definitionActions()
    actions = struct( ...
        "referenceChosen", @onReferenceChosen, ...
        "referenceCleared", @onReferenceCleared, ...
        "movingChosen", @onMovingChosen, ...
        "movingCleared", @onMovingCleared, ...
        "previewChanged", @onPreviewChanged, ...
        "startPointMatching", @onStartPointMatching, ...
        "pointPairsEdited", @onPointPairsEdited, ...
        "applyPointAlignment", @onApplyPointAlignment, ...
        "cancelPointMatching", @onCancelPointMatching, ...
        "undoPointPair", @onUndoPointPair, ...
        "autoAlign", @onAutoAlign, ...
        "startCropRoi", @onStartCropRoi, ...
        "cropRectMoved", @onCropRectMoved, ...
        "applyCropRoi", @onApplyCropRoi, ...
        "cancelCropRoi", @onCancelCropRoi, ...
        "undoEdit", @onUndoEdit, ...
        "saveCurrentImages", @onSaveCurrentImages, ...
        "resetToOriginals", @onResetToOriginals, ...
        "startMaskEdit", @onStartMaskEdit, ...
        "maskPointsEdited", @onMaskPointsEdited, ...
        "boundaryStyleChanged", @onBoundaryStyleChanged, ...
        "previewMaskRoi", @onPreviewMaskRoi, ...
        "addBoundaryToMask", @onAddBoundaryToMask, ...
        "subtractBoundaryFromMask", @onSubtractBoundaryFromMask, ...
        "undoMaskAnchor", @onUndoMaskAnchor, ...
        "undoMaskEdit", @onUndoMaskEdit, ...
        "clearMaskBoundary", @onClearMaskBoundary, ...
        "clearMaskCanvas", @onClearMaskCanvas, ...
        "saveMask", @onSaveMask);
end

function state = onReferenceChosen(state, event, services)
    state = onImageChosen(state, event, services, "reference");
end

function state = onMovingChosen(state, event, services)
    state = onImageChosen(state, event, services, "moving");
end

function state = onImageChosen(state, event, services, role)
    paths = services.events.paths(event, "addedFiles");
    if isempty(paths)
        state = services.workflow.log(state, titleCase(role) + ...
            " image selection cancelled.");
        return;
    end
    filepath = paths(1);
    try
        imageData = imread(filepath);
    catch ME
        services.diagnostics.report('Image load failed', ME);
        services.dialogs.alert(ME.message, ...
            'Image load failed');
        return;
    end
    state.project.inputs.sources = setSource( ...
        state.project.inputs.sources, role, filepath, services);
    cacheField = char(role + "Image");
    state.session.cache.(cacheField) = imageData;
    state.project = dic_preprocess.appState.resetForNewInput(state.project);
    state = rebuildCache(state);
    state = stopEditors(state);
    state.project.parameters.previewMode = defaultPreviewMode(state);
    state.session.workflow.details = {sprintf('Loaded %s image.', role)};
    state = clearResults(state);
    state = services.workflow.log(state, ...
        "Loaded " + role + " image: " + filepath);
end

function state = onReferenceCleared(state, ~, services)
    state = onImageCleared(state, services, "reference");
end

function state = onMovingCleared(state, ~, services)
    state = onImageCleared(state, services, "moving");
end

function state = onImageCleared(state, services, role)
    state.project.inputs.sources = removeSource( ...
        state.project.inputs.sources, role);
    state.session.cache.(char(role + "Image")) = [];
    state.project = dic_preprocess.appState.resetForNewInput(state.project);
    state = rebuildCache(state);
    state = stopEditors(state);
    state.project.parameters.previewMode = defaultPreviewMode(state);
    state = clearResults(state);
    state = services.workflow.log(state, "Cleared " + role + " image file.");
end

function state = onPreviewChanged(state, ~, ~)
    state = stopEditors(state);
end

function state = onStartPointMatching(state, ~, services)
    if alertIfMissingPair(state, services, ...
            'Load both reference and moving images before alignment.', ...
            'Missing images')
        return;
    end
    state = stopEditors(state);
    state.project.annotations.matchReferencePoints = zeros(0, 2);
    state.project.annotations.matchMovingPoints = zeros(0, 2);
    state.project.parameters.previewMode = "Current pair";
    state.session.workflow.mode = "matching";
    state.session.workflow.details = { ...
        ['Point matching active. Select corresponding features in the ' ...
        'reference and moving previews; at least two pairs are required.']};
    state = services.workflow.log(state, ...
        "Started point matching in the main reference and moving previews.");
end

function state = onPointPairsEdited(state, event, ~)
    if ~iscell(event.value) || numel(event.value) ~= 2
        return;
    end
    referencePoints = double(event.value{1});
    movingPoints = double(event.value{2});
    referenceCount = size(referencePoints, 1);
    movingCount = size(movingPoints, 1);
    if movingCount > referenceCount || referenceCount > movingCount + 1
        state.session.workflow.details = { ...
            'Select each reference feature before its moving-image match.'};
        return;
    end
    state.project.annotations.matchReferencePoints = referencePoints;
    state.project.annotations.matchMovingPoints = movingPoints;
    if referenceCount > movingCount
        instruction = 'Now select the matching feature in the moving image.';
    else
        instruction = 'Select the next feature in the reference image.';
    end
    state.session.workflow.details = {sprintf( ...
        'Complete point pairs: %d. %s', movingCount, instruction)};
end

function state = onApplyPointAlignment(state, ~, services)
    referencePoints = state.project.annotations.matchReferencePoints;
    movingPoints = state.project.annotations.matchMovingPoints;
    if size(referencePoints, 1) < 2 || ...
            size(referencePoints, 1) ~= size(movingPoints, 1)
        services.dialogs.alert( ...
            'Rigid registration requires at least two complete point pairs.', ...
            'Not enough points');
        return;
    end
    state = pushEditHistory(state, 'manual alignment');
    cache = state.session.cache;
    try
        [~, transform] = dic_preprocess.analysisRun.alignMovingToReference( ...
            cache.currentReferenceImage, cache.currentMovingImage, ...
            referencePoints, movingPoints);
    catch ME
        services.diagnostics.report('Point alignment failed', ME);
        services.dialogs.alert(ME.message, ...
            'Point alignment failed');
        return;
    end
    state.project = appendEditStep(state.project, ...
        "alignment", transform, [], "manual alignment");
    state.project = ...
        dic_preprocess.appState.clearOperationDerivedState(state.project);
    state = rebuildCache(state);
    state = stopEditors(state);
    state.project.parameters.previewMode = "False-color overlay";
    state.session.workflow.details = ...
        dic_preprocess.userInterface.transformSummary( ...
        transform, size(state.session.cache.currentReferenceImage), ...
        size(state.session.cache.currentMovingImage));
    state = clearResults(state);
    state = services.workflow.log(state, sprintf( ...
        'Aligned image using %d point pair(s).', size(referencePoints, 1)));
end

function state = onCancelPointMatching(state, ~, services)
    if state.session.workflow.mode ~= "matching"
        return;
    end
    state = stopEditors(state);
    state.session.workflow.details = {'Point matching cancelled.'};
    state = services.workflow.log(state, "Cancelled point matching.");
end

function state = onUndoPointPair(state, ~, ~)
    reference = state.project.annotations.matchReferencePoints;
    moving = state.project.annotations.matchMovingPoints;
    if isempty(reference)
        return;
    end
    if size(reference, 1) > size(moving, 1)
        reference(end, :) = [];
    else
        reference(end, :) = [];
        if ~isempty(moving)
            moving(end, :) = [];
        end
    end
    state.project.annotations.matchReferencePoints = reference;
    state.project.annotations.matchMovingPoints = moving;
end

function state = onAutoAlign(state, ~, services)
    if alertIfMissingPair(state, services, ...
            'Load both reference and moving images before automatic alignment.', ...
            'Missing images')
        return;
    end
    state = stopEditors(state);
    cache = state.session.cache;
    try
        [~, transform, method] = ...
            dic_preprocess.analysisRun.autoAlignMovingToReference( ...
            cache.currentReferenceImage, cache.currentMovingImage);
    catch ME
        services.diagnostics.report('Automatic alignment failed', ME);
        services.dialogs.alert(sprintf( ...
            'Automatic alignment failed:\n%s', ME.message), ...
            'Auto align failed');
        state = services.workflow.log(state, ...
            "Automatic alignment failed: " + ME.message);
        return;
    end
    state = pushEditHistory(state, 'automatic alignment');
    state.project = appendEditStep(state.project, ...
        "alignment", transform, [], "automatic alignment");
    state.project = ...
        dic_preprocess.appState.clearOperationDerivedState(state.project);
    state = rebuildCache(state);
    state.project.parameters.previewMode = "False-color overlay";
    state.session.workflow.details = ...
        dic_preprocess.userInterface.transformSummary( ...
        transform, size(state.session.cache.currentReferenceImage), ...
        size(state.session.cache.currentMovingImage));
    state = clearResults(state);
    state = services.workflow.log(state, ...
        "Automatically aligned current pair using " + string(method) + ".");
end

function state = onStartCropRoi(state, ~, services)
    if alertIfMissingPair(state, services, ...
            'Load both reference and moving images before cropping.', ...
            'Missing images')
        return;
    end
    state = stopEditors(state);
    state.project.annotations.cropRect = ...
        dic_preprocess.analysisRun.defaultSquareRect( ...
        size(state.session.cache.currentReferenceImage));
    state.project.parameters.previewMode = "Current pair";
    state.session.workflow.mode = "crop";
    state.session.workflow.details = ...
        dic_preprocess.userInterface.cropSelectionSummary( ...
        state.project.annotations.cropRect);
    state = services.workflow.log(state, ...
        "Started crop ROI on the current pair preview.");
end

function state = onCropRectMoved(state, event, ~)
    if state.session.workflow.mode ~= "crop" || numel(event.value) ~= 4
        return;
    end
    rect = dic_preprocess.analysisRun.squareRectInsideImage( ...
        double(event.value), size(state.session.cache.currentReferenceImage));
    state.project.annotations.cropRect = rect;
    state.session.workflow.details = ...
        dic_preprocess.userInterface.cropSelectionSummary(rect);
end

function state = onApplyCropRoi(state, ~, services)
    rect = state.project.annotations.cropRect;
    if state.session.workflow.mode ~= "crop" || isempty(rect)
        services.dialogs.alert( ...
            'Start a crop ROI before applying the crop.', 'No active ROI');
        return;
    end
    state = pushEditHistory(state, 'crop');
    cache = state.session.cache;
    rect = dic_preprocess.analysisRun.squareRectInsideImage( ...
        rect, size(cache.currentReferenceImage));
    state.project = appendEditStep(state.project, ...
        "crop", [], rect, "crop");
    state.project.annotations.cropRect = rect;
    state.project = ...
        dic_preprocess.appState.clearOperationDerivedState(state.project);
    state = rebuildCache(state);
    state = stopEditors(state);
    state.project.parameters.previewMode = "Current pair";
    state.session.workflow.details = dic_preprocess.userInterface.cropSummary(rect);
    state = clearResults(state);
    state = services.workflow.log(state, sprintf( ...
        'Cropped current pair with [%g %g %g %g].', rect));
end

function state = onCancelCropRoi(state, ~, services)
    if state.session.workflow.mode ~= "crop"
        return;
    end
    state = stopEditors(state);
    state = services.workflow.log(state, "Crop ROI cancelled.");
end

function state = onUndoEdit(state, ~, services)
    history = state.project.annotations.history;
    if isempty(history)
        services.dialogs.alert( ...
            'No align or crop operation is available to undo.', 'Undo');
        return;
    end
    snapshot = history(end);
    history(end) = [];
    state.project.annotations.history = history;
    state.project = dic_preprocess.appState.restoreEditSnapshot( ...
        state.project, snapshot);
    state = rebuildCache(state);
    state = stopEditors(state);
    state.project.parameters.previewMode = "Current pair";
    state.session.workflow.details = {sprintf( ...
        'Restored state before %s.', snapshot.description)};
    state = clearResults(state);
    state = services.workflow.log(state, "Undid " + string(snapshot.description) + ".");
end

function state = onResetToOriginals(state, ~, services)
    if isempty(state.session.cache.referenceImage) || ...
            isempty(state.session.cache.movingImage)
        services.dialogs.alert( ...
            'Load both images before resetting the working pair.', 'Reset');
        return;
    end
    state = pushEditHistory(state, 'reset to originals');
    state.project = dic_preprocess.appState.resetToOriginals(state.project);
    state = rebuildCache(state);
    state = stopEditors(state);
    state.project.parameters.previewMode = "Current pair";
    state.session.workflow.details = {'Current working pair reset to originals.'};
    state = clearResults(state);
    state = services.workflow.log(state, ...
        "Reset current working pair to the original loaded images.");
end

function state = onSaveCurrentImages(state, ~, services)
    if alertIfMissingPair(state, services, ...
            'Load both images before saving the current pair.', ...
            'Save current images')
        return;
    end
    folderDefault = dic_preprocess.sourceFiles.defaultSaveFolder( ...
        dic_preprocess.sourceFiles.pathForId( ...
        state.project.inputs.sources, "referenceImage"), ...
        dic_preprocess.sourceFiles.pathForId( ...
        state.project.inputs.sources, "movingImage"), ...
        services.dialogs.defaultFolder("output"));
    [folder, cancelled] = services.dialogs.outputFolder( ...
        'Select folder for current images', folderDefault);
    if cancelled
        state = services.workflow.log(state, "Save current images cancelled.");
        return;
    end
    outputs = dic_preprocess.resultFiles.writeCurrentImages( ...
        state.session.cache.currentReferenceImage, ...
        state.session.cache.currentMovingImage, folder);
    spec = struct();
    spec.Outputs = [services.results.output( ...
        "currentReference", "primary", "current_reference.png", "image/png"); ...
        services.results.output( ...
        "currentMoving", "primary", "current_moving.png", "image/png")];
    spec.Inputs = state.project.inputs.sources;
    spec.Parameters = state.project.parameters;
    spec.Summary = struct("pairSaved", true);
    spec.ManifestName = "dic_preprocess_images.labkit.json";
    [manifestPath, ~] = services.results.writeManifest(folder, spec);
    state.project.results.currentImagesManifestPath = string(manifestPath);
    state = services.workflow.log(state, ...
        "Saved current images: " + string(outputs.referencePath) + ...
        " and " + string(outputs.movingPath));
end

function state = onStartMaskEdit(state, ~, services)
    if isempty(state.session.cache.currentReferenceImage)
        services.dialogs.alert( ...
            'Load a reference image before drawing an ROI mask.', ...
            'Missing image');
        return;
    end
    state = stopEditors(state);
    state.project.annotations.maskImage = [];
    state.project.annotations.maskPoints = zeros(0, 2);
    state.project.annotations.maskHistory = ...
        state.project.annotations.maskHistory([]);
    state.session.workflow.mode = "mask";
    state.project.parameters.previewMode = "Current pair";
    state.session.workflow.details = { ...
        ['ROI edit started. Add, move, or delete anchors in the reference ' ...
        'preview, then add/subtract the boundary on the mask canvas.']};
    state = services.workflow.log(state, ...
        "Started mask ROI canvas for controlled anchor editing.");
end

function state = onMaskPointsEdited(state, event, ~)
    state.project.annotations.maskPoints = double(event.value);
    state.session.workflow.details = ...
        dic_preprocess.userInterface.maskDraftDetails( ...
        state.project.annotations.maskPoints);
end

function state = onBoundaryStyleChanged(state, ~, ~)
    state.session.workflow.details = { ...
        'Boundary style: ' + string(state.project.parameters.maskBoundaryStyle) + '.'};
end

function state = onPreviewMaskRoi(state, ~, services)
    [boundaryMask, ok] = currentBoundaryMask(state);
    if ok
        state.project.parameters.previewMode = "ROI mask";
        state.session.workflow.details = { ...
            'Boundary preview updated. Add it to the mask canvas, subtract it, or keep editing anchors.'};
        state = services.workflow.log(state, sprintf( ...
            'Previewed %s ROI boundary with %d anchors.', ...
            state.project.parameters.maskBoundaryStyle, ...
            size(state.project.annotations.maskPoints, 1)));
    elseif ~isempty(state.project.annotations.maskImage)
        state.project.parameters.previewMode = "ROI mask";
    else
        services.dialogs.alert( ...
            'Mask ROI needs at least three anchors.', 'Not enough anchors');
    end
end

function state = onAddBoundaryToMask(state, ~, services)
    state = applyBoundary(state, services, "add");
end

function state = onSubtractBoundaryFromMask(state, ~, services)
    state = applyBoundary(state, services, "subtract");
end

function state = applyBoundary(state, services, operation)
    [boundaryMask, ok] = currentBoundaryMask(state);
    if ~ok
        services.dialogs.alert( ...
            'Mask ROI needs at least three anchors.', 'Not enough anchors');
        return;
    end
    state = pushMaskHistory(state, operation + " boundary");
    state.project.annotations.maskImage = ...
        dic_preprocess.appState.applyBoundaryToMask( ...
        state.project.annotations.maskImage, ...
        state.session.cache.currentReferenceImage, boundaryMask, operation);
    state.project.parameters.previewMode = "ROI mask";
    state = clearResults(state);
    state = services.workflow.log(state, titleCase(operation) + "ed " + ...
        state.project.parameters.maskBoundaryStyle + ...
        " boundary on the ROI mask canvas.");
end

function state = onUndoMaskAnchor(state, ~, ~)
    points = state.project.annotations.maskPoints;
    if ~isempty(points)
        points(end, :) = [];
        state.project.annotations.maskPoints = points;
    end
end

function state = onUndoMaskEdit(state, ~, services)
    history = state.project.annotations.maskHistory;
    if isempty(history)
        return;
    end
    snapshot = history(end);
    history(end) = [];
    state.project.annotations.maskHistory = history;
    state.project = dic_preprocess.appState.restoreMaskSnapshot( ...
        state.project, snapshot);
    state.project.parameters.previewMode = "ROI mask";
    state = clearResults(state);
    state = services.workflow.log(state, ...
        "Undid mask edit: " + string(snapshot.description) + ".");
end

function state = onClearMaskBoundary(state, ~, services)
    state.project.annotations.maskPoints = zeros(0, 2);
    state = services.workflow.log(state, "Cleared mask ROI boundary anchors.");
end

function state = onClearMaskCanvas(state, ~, services)
    if isempty(state.project.annotations.maskImage)
        return;
    end
    state = pushMaskHistory(state, 'clear mask canvas');
    state.project.annotations.maskImage = [];
    state = clearResults(state);
    state = services.workflow.log(state, "Cleared ROI mask canvas.");
end

function state = onSaveMask(state, ~, services)
    mask = state.project.annotations.maskImage;
    if isempty(mask)
        [mask, ok] = currentBoundaryMask(state);
        if ~ok
            services.dialogs.alert( ...
                'Draw a mask ROI or add a boundary before saving.', ...
                'Save ROI mask');
            return;
        end
        state.project.annotations.maskImage = mask;
    end
    defaultName = dic_preprocess.sourceFiles.defaultMaskPath( ...
        dic_preprocess.sourceFiles.pathForId( ...
        state.project.inputs.sources, "referenceImage"), ...
        services.dialogs.defaultFolder("output"));
    [outfile, cancelled] = services.dialogs.outputFile( ...
        {'*.png', 'PNG mask'}, 'Save ROI mask', defaultName);
    if cancelled
        state = services.workflow.log(state, "Save ROI mask cancelled.");
        return;
    end
    dic_preprocess.resultFiles.writeMask(mask, outfile);
    [folder, name, extension] = fileparts(outfile);
    spec = struct();
    spec.Outputs = services.results.output("roiMask", "primary", ...
        string(name) + string(extension), "image/png");
    spec.Inputs = state.project.inputs.sources;
    spec.Parameters = state.project.parameters;
    spec.Summary = struct("anchorCount", ...
        size(state.project.annotations.maskPoints, 1));
    spec.ManifestName = string(name) + ".labkit.json";
    [manifestPath, ~] = services.results.writeManifest(folder, spec);
    state.project.results.maskManifestPath = string(manifestPath);
    state = services.workflow.log(state, "Saved ROI mask: " + string(outfile));
end

function state = pushEditHistory(state, description)
    state.project = dic_preprocess.appState.appendEditHistory( ...
        state.project, description);
end

function state = pushMaskHistory(state, description)
    state.project = dic_preprocess.appState.appendMaskHistory( ...
        state.project, description);
end

function project = appendEditStep(project, kind, transform, rect, description)
    step = struct( ...
        "kind", string(kind), ...
        "transform", transform, ...
        "rect", rect, ...
        "description", string(description));
    steps = project.annotations.editSteps;
    if isempty(steps)
        steps = step;
    else
        steps(end + 1) = step;
    end
    project.annotations.editSteps = steps;
end

function state = rebuildCache(state)
    cache = state.session.cache;
    state.session.cache = dic_preprocess.analysisRun.replayEditSteps( ...
        cache.referenceImage, cache.movingImage, ...
        state.project.annotations.editSteps);
end

function [mask, ok] = currentBoundaryMask(state)
    [mask, ok] = dic_preprocess.analysisRun.boundaryMaskFromEditor( ...
        state.project.annotations.maskPoints, ...
        size(state.session.cache.currentReferenceImage), ...
        state.project.parameters.maskBoundaryStyle, []);
end

function state = stopEditors(state)
    state.session.workflow.mode = "idle";
    state.project.annotations.matchReferencePoints = zeros(0, 2);
    state.project.annotations.matchMovingPoints = zeros(0, 2);
end

function tf = alertIfMissingPair(state, services, message, titleText)
    tf = ~dic_preprocess.appState.hasImagePair(state.session.cache);
    if tf
        services.dialogs.alert(message, titleText);
    end
end

function value = defaultPreviewMode(state)
    if ~dic_preprocess.appState.hasImagePair(state.session.cache)
        value = "Current pair";
    else
        value = "False-color overlay";
    end
end

function state = clearResults(state)
    state.project.results.currentImagesManifestPath = "";
    state.project.results.maskManifestPath = "";
end

function sources = setSource(sources, role, filepath, services)
    source = services.project.sourceRecord( ...
        role + "Image", role, filepath, true);
    if isempty(sources)
        sources = source;
        return;
    end
    match = find(string({sources.id}) == source.id, 1, 'first');
    if isempty(match)
        sources(end + 1) = source;
    else
        sources(match) = source;
    end
end

function sources = removeSource(sources, role)
    if isempty(sources)
        return;
    end
    sources(string({sources.id}) == role + "Image") = [];
end

function value = titleCase(value)
    value = char(string(value));
    value(1) = upper(value(1));
    value = string(value);
end
