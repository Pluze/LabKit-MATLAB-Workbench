% Expected caller: the Figure Studio X-maximum numeric control. Inputs are
% runtime state, an unused event value, and callback context. Output is state
% with the validated viewport override; side effects are status reporting.
function state = xMaxChanged(state, ~, callbackContext)
%XMAXCHANGED Apply an editable Figure Studio X-axis maximum.
state = figure_studio.sourceAxes.limitChanged(state, "xMax", callbackContext);
end
