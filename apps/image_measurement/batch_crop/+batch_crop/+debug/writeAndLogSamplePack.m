% Expected caller: definitionActions during debug launch. Inputs are a debug
% context and app log callback. Side effects: writes debug samples and logs
% their artifact locations without mutating app state.
function writeAndLogSamplePack(debugLog, addLog)
    try
        pack = batch_crop.debug.writeSamplePack(debugLog);
        addLog(sprintf('Debug sample files: %s', char(pack.sampleFolder)));
        addLog(sprintf('Debug output folder: %s', char(pack.outputFolder)));
    catch ME
        debugLog.reportException('batchCrop', 'Debug sample setup failed', ME);
        addLog(sprintf('Debug sample setup failed: %s', ME.message));
    end
end
