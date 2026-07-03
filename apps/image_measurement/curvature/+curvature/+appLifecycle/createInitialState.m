% Initial state factory for Curvature Measurement. Expected caller is
% curvature.definition. Output is the app-owned model consumed by action
% handlers and UI update functions.
function S = createInitialState()
    S = struct();
    S.imagePath = "";
    S.image = [];
    S.xPix = [];
    S.yPix = [];
    S.curveEditor = [];
    S.curveEditActive = false;
    S.fit = curvature.appState.emptyFitResult();
    S.length = curvature.appState.emptyLengthResult();
    S.lastFitFingerprint = "";
    S.lastLengthFingerprint = "";
end
