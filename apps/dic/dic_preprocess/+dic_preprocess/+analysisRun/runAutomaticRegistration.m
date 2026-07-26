% App-owned implementation for dic_preprocess.analysisRun.runAutomaticRegistration within the dic_preprocess product workflow.
function state = runAutomaticRegistration(state, context)
%RUNAUTOMATICREGISTRATION Estimate and record a rigid registration transform.
cache = state.session.cache;
if isempty(cache.currentReferenceImage) || isempty(cache.currentMovingImage)
    context.alert('Load both reference and moving images before automatic alignment.', 'Missing images');
    return;
end
try
    [~, transform, method] = dic_preprocess.analysisRun.autoAlignMovingToReference( ...
        cache.currentReferenceImage, cache.currentMovingImage);
catch ME
    context.log("error", "dic_preprocess.analysisrun.runautomaticregistration.exception", 'Automatic alignment', ...
        Category="failure", Audience="developer", Exception=ME);
    context.alert("Automatic alignment failed:" + newline + ME.message, 'Auto align failed');
    return;
end
state = dic_preprocess.analysisRun.recordAlignment(state, transform, "automatic alignment");
context.log("info", "dic_preprocess.analysisrun.runautomaticregistration.status",  ...
    "Automatically aligned current pair using " + string(method) + ".");
end
