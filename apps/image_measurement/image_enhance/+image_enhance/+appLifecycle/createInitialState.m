% Create initial Image Enhance app state. Expected caller is
% image_enhance.definition via labkit.ui.runtime.define. Output is the mutable
% app session struct; side effects are none.
function S = createInitialState()
    S = struct();
    S.items = repmat(image_enhance.appState.emptyItem(), 0, 1);
    S.currentIndex = 0;
    S.steps = repmat(image_enhance.appState.emptyStep(), 0, 1);
    S.batchMode = true;
    S.outputFolder = string(labkit.ui.runtime.defaultDialogFolder("output"));
    S.lastExport = [];
    S.lastExportFingerprint = "";
    S.pendingDirty = false;
    S.previewImages = {};
    S.previewImageKeys = strings(0, 1);
    S.previewScales = [];
    S.previewResultImage = [];
    S.previewResultKey = "";
    S.whiteRoiHandle = [];
    S.whiteRoiListener = [];
end
