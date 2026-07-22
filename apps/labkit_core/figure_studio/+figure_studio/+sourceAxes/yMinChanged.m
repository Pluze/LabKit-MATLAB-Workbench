function state = yMinChanged(state, ~, callbackContext)
%YMINCHANGED Apply an editable Figure Studio Y-axis minimum.
state = figure_studio.sourceAxes.limitChanged(state, "yMin", callbackContext);
end
