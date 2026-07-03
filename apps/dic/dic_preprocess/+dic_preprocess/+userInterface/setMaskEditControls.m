% Expected caller: DIC preprocess runner. Inputs are app state, control handles,
% and desired edit-active flag. Output is the updated state. Side effect: updates
% boundary dropdown and mask button Enable values.

function S = setMaskEditControls(S, controls, enabled)
%SETMASKEDITCONTROLS Set DIC preprocess mask edit control state.

    S.maskEditActive = enabled;
    controls.ddBoundaryStyle.Enable = dic_preprocess.userInterface.onOff(enabled);
    dic_preprocess.userInterface.updateMaskEditControls(controls, S);
end
