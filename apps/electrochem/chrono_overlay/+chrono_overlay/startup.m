% Expected caller: the LabKit V2 runtime Start hook. Inputs are canonical
% state, startup event, and services. Output records debug sample locations in
% workflow state while preserving normal-launch behavior.
function state = startup(state, ~, services)
    debugLog = services.debug;
    if ~isDebugEnabled(debugLog)
        return;
    end
    debugLog.trace('Chrono overlay debug trace enabled.');
    try
        pack = chrono_overlay.debug.writeSamplePack(debugLog);
        state = appendLog(state, "Debug sample files: " + pack.sampleFolder);
        state = appendLog(state, "Debug output folder: " + pack.outputFolder);
    catch ME
        debugLog.reportException('chronoOverlay', ...
            'Debug sample setup failed', ME);
        state = appendLog(state, "Debug sample setup failed: " + ME.message);
    end
end

function state = appendLog(state, message)
    state.session.workflow.logLines(end + 1, 1) = string(message);
end

function tf = isDebugEnabled(debugLog)
    tf = isstruct(debugLog) && isfield(debugLog, 'enabled') && ...
        logical(debugLog.enabled);
end
