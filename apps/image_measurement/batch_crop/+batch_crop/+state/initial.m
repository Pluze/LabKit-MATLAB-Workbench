% Initial state for Batch Image Crop. Expected caller is
% batch_crop.definition. Output is the app-owned model consumed by actions
% and renderers.
function state = initial()
    state = struct();
    state.items = repmat(batch_crop.state.emptyItem(), 0, 1);
    state.currentIndex = 0;
    state.outputFolder = "";
    state.lastExport = [];
    state.lastExportFingerprint = "";
    state.canvasCache = batch_crop.state.emptyCanvasCache();
    state.cropDefaultsInitialized = false;
    state.previewView = [];
    state.tools = [];
end
