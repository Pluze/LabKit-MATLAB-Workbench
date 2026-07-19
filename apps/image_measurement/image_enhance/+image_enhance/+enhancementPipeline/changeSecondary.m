function state=changeSecondary(state,value,~)
state.session.view.toolSecondary=double(value);state.session.workflow.pendingDirty=true;
end
