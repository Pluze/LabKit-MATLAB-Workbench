% Expected caller: the LabKit V2 runtime Start hook. Inputs are canonical
% state, startup event, and services. Output initializes a default export
% folder and records debug sample locations without creating live UI tools.
function state = startup(state, ~, services)
    if strlength(state.project.parameters.outputFolder) == 0
        state.project.parameters.outputFolder = string( ...
            services.dialogs.defaultFolder("output"));
    end
    if ~isDebugEnabled(services.debug)
        return;
    end
    services.debug.trace('Batch image crop debug trace enabled.');
    state = services.workflow.log(state, "Batch image crop debug trace enabled.");
    try
        pack = batch_crop.debug.writeSamplePack(services.debug);
        state = services.workflow.log(state, ...
            "Debug sample files: " + string(pack.sampleFolder));
        state = services.workflow.log(state, ...
            "Debug output folder: " + string(pack.outputFolder));
    catch ME
        services.diagnostics.report('Debug sample setup failed', ME);
        state = services.workflow.log(state, "Debug sample setup failed: " + ME.message);
    end
end

function tf = isDebugEnabled(debugLog)
    tf = isstruct(debugLog) && isfield(debugLog, 'enabled') && ...
        logical(debugLog.enabled);
end
