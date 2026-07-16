% Expected caller: the LabKit V2 runtime Start hook. Inputs are canonical
% state, startup event, and services. Output initializes the default export
% folder; the runtime owns debug sample generation.
function state = startup(state, ~, services)
    if strlength(state.project.parameters.outputFolder) == 0
        state.project.parameters.outputFolder = string( ...
            services.dialogs.defaultFolder("output"));
    end
end
