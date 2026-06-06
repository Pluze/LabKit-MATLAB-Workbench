% Expected caller: DIC preprocess runner. Inputs are control handles and app
% state. Side effect: updates the align/crop undo button Enable value.

function updateUndoButton(controls, S)
%UPDATEUNDOBUTTON Apply DIC preprocess undo-button state.

    controls.btnUndoEdit.Enable = dic_preprocess.view.onOff(~isempty(S.history));
end
