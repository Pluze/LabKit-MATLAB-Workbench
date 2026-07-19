function state=changeAmount(state,value,~)
state.session.view.toolAmount=double(value);state.session.workflow.pendingDirty=true;
end
