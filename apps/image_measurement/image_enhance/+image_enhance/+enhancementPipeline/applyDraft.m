% App-owned implementation for image_enhance.enhancementPipeline.applyDraft within the image_enhance product workflow.
function state=applyDraft(state,context)
%APPLYDRAFT Commit the selected enhancement draft to the active history.
availability = ...
    image_enhance.imagePreview.presentationData.toolAvailability( ...
        state, state.session.view.toolKind);
if ~availability.canApply
    context.alert(availability.status, "Tool unavailable");
    return;
end
step=image_enhance.analysisRun.makeStep(state.session.view.toolKind, ...
    state.session.view.toolAmount,state.session.view.toolSecondary,0);
steps = image_enhance.analysisRun.activeSteps(state);
steps = steps(:);
steps(end + 1, 1) = step;
state = image_enhance.analysisRun.setActiveSteps(state, steps);
state.session.workflow.pendingDirty=false;
state.session.view.roiEditing = false;
state = image_enhance.enhancementPipeline.invalidateResults(state);
state.session.cache.previewResult = [];
state.session.cache.previewResultKey = "";
state = image_enhance.enhancementPipeline.rebuildPreview(state);
context.appendStatus("Applied tool: " + string(step.label));
end
