% Expected caller: image_enhance.definition during synthetic-input generation. Inputs are a debug
% context and app log callback. Side effects: writes synthetic inputs and logs
% their artifact locations without mutating app state.
function writeAndLogSamplePack(debugLog, addLog)
    try
        pack = image_enhance.syntheticInputs.writeSamplePack(debugLog);
        addLog(sprintf('Debug sample files: %s', char(pack.sampleFolder)));
        addLog(sprintf('Debug output folder: %s', char(pack.outputFolder)));
    catch ME
        debugLog.reportException('imageEnhance', 'Debug sample setup failed', ME);
        addLog(sprintf('Debug sample setup failed: %s', ME.message));
    end
end
