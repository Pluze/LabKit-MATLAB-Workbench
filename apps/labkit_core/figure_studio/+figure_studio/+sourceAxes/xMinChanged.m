function state = xMinChanged(state, ~, callbackContext)
%XMINCHANGED Apply an editable Figure Studio X-axis minimum.
state = figure_studio.sourceAxes.limitChanged(state, "xMin", callbackContext);
end
