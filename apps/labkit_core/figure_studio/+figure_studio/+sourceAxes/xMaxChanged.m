function state = xMaxChanged(state, ~, callbackContext)
%XMAXCHANGED Apply an editable Figure Studio X-axis maximum.
state = figure_studio.sourceAxes.limitChanged(state, "xMax", callbackContext);
end
