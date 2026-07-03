% App-owned runtime definition for labkit_ImageEnhance_app. Expected caller:
% the public app entrypoint. Output is a declarative LabKit app definition;
% side effects are none.
function def = definition()
    stepKinds = {'Brightness/contrast', 'Local contrast', 'Sharpen', ...
        'Hue/saturation', 'White balance', 'White ROI calibration', ...
        'Subject-preserving enhance'};
    def = labkit.ui.app.define( ...
        "Id", "image_enhance", ...
        "Title", "Paper Image Enhance", ...
        "InitialState", @initialState, ...
        "Spec", @(callbacks, state) image_enhance.ui.buildSpec( ...
            stepKinds, char(state.outputFolder), callbacks), ...
        "Actions", image_enhance.actions.table(), ...
        "Render", @image_enhance.view.render, ...
        "Startup", "startup");
end

function S = initialState()
    S = struct();
    S.items = repmat(image_enhance.state.emptyItem(), 0, 1);
    S.currentIndex = 0;
    S.steps = repmat(image_enhance.state.emptyStep(), 0, 1);
    S.batchMode = true;
    S.outputFolder = string(labkit.ui.app.defaultDialogFolder("output"));
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
