% Expected caller: the LabKit V2 runtime Start hook. Inputs are canonical
% state, startup event, and services. Output records debug sample locations in
% workflow state while preserving normal-launch behavior.
function state = startup(state, ~, services)
    debugLog = services.debug;
    if ~isDebugEnabled(debugLog)
        return;
    end
    debugLog.trace('DIC postprocess debug trace enabled.');
    try
        pack = dic_postprocess.debug.writeSamplePack(debugLog);
        state = services.workflow.log(state, "Debug sample files: " + pack.sampleFolder);
        state = services.workflow.log(state, "Debug output folder: " + pack.outputFolder);
    catch ME
        services.diagnostics.report('Debug sample setup failed', ME);
        state = services.workflow.log(state, "Debug sample setup failed: " + ME.message);
    end
end

function tf = isDebugEnabled(debugLog)
    tf = isstruct(debugLog) && isfield(debugLog, 'enabled') && ...
        logical(debugLog.enabled);
end
