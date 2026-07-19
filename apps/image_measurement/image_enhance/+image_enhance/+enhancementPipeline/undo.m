function state=undo(state,~)
steps=state.project.annotations.sharedSteps;if ~isempty(steps),steps(end)=[];end
state.project.annotations.sharedSteps=steps;
end
