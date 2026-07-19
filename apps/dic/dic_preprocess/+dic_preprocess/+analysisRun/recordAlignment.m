function state = recordAlignment(state, transform, description)
%RECORDALIGNMENT Persist one alignment step and replay the transient images.
state.project = dic_preprocess.editHistory.appendEditHistory(state.project, description);
step = struct("kind", "alignment", "transform", transform, "rect", [], ...
    "description", string(description));
steps = state.project.annotations.editSteps;
if isempty(steps), steps = step; else, steps(end+1) = step; end
state.project.annotations.editSteps = steps;
state.project = dic_preprocess.maskEditing.clearOperationDerivedState(state.project);
cache = state.session.cache;
state.session.cache = dic_preprocess.analysisRun.replayEditSteps( ...
    cache.referenceImage, cache.movingImage, steps);
state.session.workflow.mode = "idle";
state.project.annotations.matchReferencePoints = zeros(0,2);
state.project.annotations.matchMovingPoints = zeros(0,2);
state.project.parameters.previewMode = "False-color overlay";
state.session.workflow.details = ...
    dic_preprocess.analysisRun.transformSummary( ...
        transform, size(state.session.cache.currentReferenceImage), ...
        size(state.session.cache.currentMovingImage));
state.project.results.currentImagesManifestPath = "";
state.project.results.maskManifestPath = "";
end
