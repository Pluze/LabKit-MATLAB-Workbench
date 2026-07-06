% CSC render hook for the transitional LabKit app runtime. Expected caller:
% labkit.ui.runtime.run after CSC actions complete. CSC callbacks currently
% refresh the affected UI regions directly, so this hook intentionally has no
% additional side effects.
function updateWorkbenchFromState(~, ~, ~)
end
