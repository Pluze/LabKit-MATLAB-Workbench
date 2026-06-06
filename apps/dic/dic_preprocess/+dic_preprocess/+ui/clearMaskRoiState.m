% Expected caller: DIC preprocess runner. Inputs are app state and controls.
% Output clears active mask editor/points and disables mask edit controls. Side
% effect: deletes the active anchor editor when present.

function S = clearMaskRoiState(S, controls)
%CLEARMASKROISTATE Clear DIC preprocess mask editor state and controls.

    dic_preprocess.ui.clearMaskEditor(S.maskEditor);
    S.maskEditor = [];
    S.maskPoints = [];
    S = dic_preprocess.ui.setMaskEditControls(S, controls, false);
end
