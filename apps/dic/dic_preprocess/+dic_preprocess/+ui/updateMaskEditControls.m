% Expected caller: DIC preprocess runner. Inputs are control handles and app
% state. Side effect: updates mask edit button Enable values from state.

function updateMaskEditControls(controls, S)
%UPDATEMASKEDITCONTROLS Apply DIC preprocess mask control enable states.

    state = dic_preprocess.view.maskEditControlState( ...
        S.maskEditActive, S.maskPoints, S.maskImage, S.maskHistory);
    controls.btnPreviewMask.Enable = state.preview;
    controls.btnUnionMask.Enable = state.addBoundary;
    controls.btnSubtractMask.Enable = state.subtractBoundary;
    controls.btnUndoMask.Enable = state.undoPoint;
    controls.btnClearBoundary.Enable = state.clearBoundary;
    controls.btnUndoMaskEdit.Enable = state.undoMaskEdit;
    controls.btnClearMask.Enable = state.clearMask;
end
