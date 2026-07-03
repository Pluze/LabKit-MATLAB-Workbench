% Expected caller: rhs_preview.actions.table during debug launch. Inputs are a debug
% context and app log callback. Side effects: writes debug samples and logs
% their artifact locations without mutating app state.
function writeAndLogSamplePack(debugLog, addLog)
    try
        pack = rhs_preview.debug.writeSamplePack(debugLog);
        addLog("Debug sample files: " + string(pack.sampleFolder));
        addLog("Debug output folder: " + string(pack.outputFolder));
    catch ME
        debugLog.reportException('rhsPreview', 'Debug sample setup failed', ME);
        addLog("Debug sample setup failed: " + string(ME.message));
    end
end
