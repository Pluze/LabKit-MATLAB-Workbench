% App-owned implementation for figure_studio.initializeWorkbench within the figure_studio product workflow.
function state = initializeWorkbench(state, callbackContext)
%INITIALIZEWORKBENCH Complete startup-only Figure Studio defaults.
arguments
    state (1, 1) struct
    callbackContext (1, 1) labkit.app.CallbackContext
end
if strlength(state.project.parameters.outputFolder) == 0
    folder = string(getenv("USERPROFILE"));
    if strlength(folder) == 0 || ~isfolder(folder)
        folder = string(getenv("HOME"));
    end
    if strlength(folder) == 0 || ~isfolder(folder)
        folder = string(pwd);
    end
    state.project.parameters.outputFolder = folder;
end
if isfield(state.project.annotations, "transientSourceAxes")
    state.project.annotations = rmfield( ...
        state.project.annotations, "transientSourceAxes");
end
if ~isempty(state.session.cache.plotData)
    callbackContext.log("info", "figure_studio.initializeworkbench.status", "Restored Figure Studio source.");
end
end
