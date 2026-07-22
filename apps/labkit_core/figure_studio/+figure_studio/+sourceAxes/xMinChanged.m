% Expected caller: the Figure Studio X-minimum numeric control. Inputs are
% runtime state, an unused event value, and callback context. Output is state
% with the validated viewport override; side effects are status reporting.
function state = xMinChanged(state, ~, callbackContext)
%XMINCHANGED Apply an editable Figure Studio X-axis minimum.
state = figure_studio.sourceAxes.limitChanged(state, "xMin", callbackContext);
end
