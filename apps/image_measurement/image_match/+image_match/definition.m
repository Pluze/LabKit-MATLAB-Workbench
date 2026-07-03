% App-owned runtime definition for labkit_ImageMatch_app. Expected caller:
% the public app entrypoint. Output is a declarative LabKit app definition;
% side effects are none.
function def = definition()
    methods = {'Balanced', 'White balance', 'Tone only', ...
        'Protected tone', 'Lab style', 'Histogram'};
    def = labkit.ui.app.define( ...
        "Id", "image_match", ...
        "Title", "Paper Image Match", ...
        "InitialState", @initialState, ...
        "Spec", @(callbacks, state) image_match.ui.buildSpec( ...
            methods, char(state.outputFolder), callbacks), ...
        "Actions", image_match.actions.table(), ...
        "Render", @image_match.view.render, ...
        "Startup", "startup");
end

function S = initialState()
    S = struct();
    S.items = repmat(image_match.state.emptyItem(), 0, 1);
    S.referenceItem = [];
    S.currentIndex = 0;
    S.steps = repmat(image_match.state.emptyStep(), 0, 1);
    S.outputFolder = string(labkit.ui.app.defaultDialogFolder("output"));
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
