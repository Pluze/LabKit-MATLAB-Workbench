% Expected caller: the Figure Studio Y-maximum numeric control. Inputs are
% runtime state, an unused event value, and callback context. Output is state
% with the validated viewport override; side effects are status reporting.
function state = yMaxChanged(state, ~, callbackContext)
%YMAXCHANGED Apply an editable Figure Studio Y-axis maximum.
state = figure_studio.sourceAxes.limitChanged(state, "yMax", callbackContext);
end
