% App-owned runtime definition for labkit_CurvatureMeasurement_app.
% Expected caller: the public app entrypoint. Output is a declarative
% LabKit app definition; side effects are none.
function def = definition()
    def = labkit.ui.app.define( ...
        "Id", "curvature", ...
        "Title", "Image Curvature Measurement", ...
        "InitialState", @initialState, ...
        "Spec", @(callbacks, ~) curvature.ui.buildSpec( ...
            callbacksWithDebugBridge(callbacks)), ...
        "Actions", curvature.actions.table(), ...
        "Render", @curvature.view.render, ...
        "Startup", "startup");
end

function callbacks = callbacksWithDebugBridge(callbacks)
    callbacks.onShowDenseChanged = @curvature.actions.refreshImageOverlay;
end

function S = initialState()
    S = struct();
    S.imagePath = "";
    S.image = [];
    S.xPix = [];
    S.yPix = [];
    S.curveEditor = [];
    S.curveEditActive = false;
    S.fit = curvature.state.emptyFitResult();
    S.length = curvature.state.emptyLengthResult();
    S.lastFitFingerprint = "";
    S.lastLengthFingerprint = "";
end
