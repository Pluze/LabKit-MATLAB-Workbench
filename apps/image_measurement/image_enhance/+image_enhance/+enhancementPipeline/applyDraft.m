function state=applyDraft(state,context)
%APPLYDRAFT Commit the selected enhancement draft to the active history.
if isempty(state.session.cache.item)
    context.alert("Load an image before applying an enhancement.","No image loaded"); return
end
step=image_enhance.analysisRun.makeStep(state.session.view.toolKind, ...
    state.session.view.toolAmount,state.session.view.toolSecondary,0);
if state.project.parameters.batchMode
    state.project.annotations.sharedSteps(end+1,1)=step;
else
    index=state.session.selection.currentIndex;
    state.project.annotations.items(index).steps(end+1,1)=step;
end
state.session.workflow.pendingDirty=false;
state.session.cache.previewResult=image_enhance.analysisRun.previewResult( ...
    state.session.cache.previewSource,image_enhance.analysisRun.activeSteps(state), ...
    activeRoi(state),state.session.cache.previewScale);
context.appendStatus("Applied enhancement: "+string(step.label));
end

function roi=activeRoi(state)
roi=[]; index=state.session.selection.currentIndex;
if ~state.project.parameters.batchMode && index>=1 && index<=numel(state.project.annotations.items)
    roi=state.project.annotations.items(index).whiteRoi;
end
end
