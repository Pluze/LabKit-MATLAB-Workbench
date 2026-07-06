% Create initial Image Match app state. Expected caller is
% image_match.definition via labkit.ui.runtime.define. Output is the mutable app
% session struct; side effects are none.
function S = createInitialState()
    S = struct();
    S.items = repmat(image_match.appState.emptyItem(), 0, 1);
    S.referenceItem = [];
    S.currentIndex = 0;
    S.steps = repmat(image_match.appState.emptyStep(), 0, 1);
    S.outputFolder = string(labkit.ui.runtime.defaultDialogFolder("output"));
    S.lastExport = [];
    S.lastExportFingerprint = "";
    S.pendingDirty = false;
    S.previewImages = {};
    S.previewImageKeys = strings(0, 1);
    S.referencePreviewImage = [];
    S.referencePreviewKey = "";
    S.previewResultImage = [];
    S.previewResultKey = "";
end
