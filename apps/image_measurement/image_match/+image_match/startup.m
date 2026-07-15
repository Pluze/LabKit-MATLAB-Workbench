% Expected caller: the LabKit V2 runtime Start hook. Output initializes the
% default export folder and records debug startup without UI-handle access.
function state = startup(state, ~, services)
    if strlength(state.project.parameters.outputFolder) == 0
        state.project.parameters.outputFolder = string( ...
            services.dialogs.defaultFolder("output"));
    end
    if services.debug.enabled
        state = services.workflow.log(state, "Image match debug trace enabled.");
    end
end
