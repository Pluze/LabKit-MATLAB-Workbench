% Expected caller: the LabKit V2 runtime Start hook. Inputs are canonical
% state, startup event, and services. Output records debug sample locations.
function state = startup(state, ~, services)
    if ~isstruct(services.debug) || ~isfield(services.debug, 'enabled') || ...
            ~logical(services.debug.enabled)
        return;
    end
    services.debug.trace('DIC preprocess debug trace enabled.');
    state = addLog(state, services, "DIC preprocess debug trace enabled.");
    try
        pack = dic_preprocess.debug.writeSamplePack(services.debug);
        state = addLog(state, services, ...
            "Debug sample files: " + string(pack.sampleFolder));
        state = addLog(state, services, ...
            "Debug output folder: " + string(pack.outputFolder));
    catch ME
        services.debug.reportException('dicPreprocess', ...
            'Debug sample setup failed', ME);
        state = addLog(state, services, ...
            "Debug sample setup failed: " + ME.message);
    end
end

function state = addLog(state, services, message)
    message = string(message);
    state.session.workflow.logLines(end + 1, 1) = message;
    services.debug.append(char(message));
end
