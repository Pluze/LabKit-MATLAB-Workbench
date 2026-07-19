function state=changeTool(state,value,~)
state.session.view.toolKind=string(value); d=image_enhance.analysisRun.defaultStepValues(value);
state.session.view.toolAmount=d.amount;state.session.view.toolSecondary=d.secondary;state.session.workflow.pendingDirty=true;
end
