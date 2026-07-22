% Expected caller: the Figure Studio Y-minimum numeric control. Inputs are
% runtime state, an unused event value, and callback context. Output is state
% with the validated viewport override; side effects are status reporting.
function state = yMinChanged(state, ~, callbackContext)
%YMINCHANGED Apply an editable Figure Studio Y-axis minimum.
state = figure_studio.sourceAxes.limitChanged(state, "yMin", callbackContext);
end
