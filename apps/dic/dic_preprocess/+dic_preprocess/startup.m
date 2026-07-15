% Expected caller: the LabKit V2 runtime Start hook. Inputs are canonical
% state, startup event, and services. Output records debug sample locations.
function state = startup(state, ~, services)
    if ~isstruct(services.debug) || ~isfield(services.debug, 'enabled') || ...
            ~logical(services.debug.enabled)
        return;
    end
    services.debug.trace('DIC preprocess debug trace enabled.');
    state = services.workflow.log(state, "DIC preprocess debug trace enabled.");
    try
        pack = dic_preprocess.debug.writeSamplePack(services.debug);
        state = services.workflow.log(state, ...
            "Debug sample files: " + string(pack.sampleFolder));
        state = services.workflow.log(state, ...
            "Debug output folder: " + string(pack.outputFolder));
    catch ME
        services.diagnostics.report('Debug sample setup failed', ME);
        state = services.workflow.log(state, ...
            "Debug sample setup failed: " + ME.message);
    end
end
