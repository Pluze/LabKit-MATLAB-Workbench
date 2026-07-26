% App-owned implementation for dic_preprocess.analysisRun.applyPointAlignment within the dic_preprocess product workflow.
function state = applyPointAlignment(state, context)
reference = state.project.annotations.matchReferencePoints;
moving = state.project.annotations.matchMovingPoints;
if size(reference,1) < 2 || size(reference,1) ~= size(moving,1)
    context.alert('Rigid registration requires at least two complete point pairs.', 'Not enough points');
    return;
end
cache = state.session.cache;
try
    [~, transform] = dic_preprocess.analysisRun.alignMovingToReference( ...
        cache.currentReferenceImage, cache.currentMovingImage, reference, moving);
catch ME
    context.log("error", "dic_preprocess.analysisrun.applypointalignment.exception", 'Point alignment', ...
        Category="failure", Audience="developer", Exception=ME);
    context.alert(ME.message, 'Point alignment failed');
    return;
end
state = dic_preprocess.analysisRun.recordAlignment(state, transform, "manual alignment");
context.log("info", "dic_preprocess.analysisrun.applypointalignment.status",  ...
    "Aligned image using " + string(size(reference,1)) + " point pair(s).");
end
