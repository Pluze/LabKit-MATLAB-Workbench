% Image Match render hook. Expected caller is
% labkit.ui.app.run after action dispatch. Rendering remains action-driven
% because callbacks refresh the affected UI regions directly; side effects
% are none.
function updateWorkbenchFromState(~, ~, ~)
end
