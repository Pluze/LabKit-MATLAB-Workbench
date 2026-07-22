function state = yMaxChanged(state, ~, callbackContext)
%YMAXCHANGED Apply an editable Figure Studio Y-axis maximum.
state = figure_studio.sourceAxes.limitChanged(state, "yMax", callbackContext);
end
