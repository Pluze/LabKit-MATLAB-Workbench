% Image Enhance render hook. Expected caller is
% labkit.ui.runtime.run after action dispatch. Rendering remains action-driven
% because callbacks refresh the affected UI regions directly; side effects
% are none.
function updateWorkbenchFromState(~, ~, ~)
end
