% Expected caller: DIC preprocess runner. Inputs are app state and control
% handles. Output resets crop ROI handles/listeners. Side effects: deletes crop
% ROI graphics/listeners and disables crop action buttons.

function S = clearCropRoiState(S, controls)
%CLEARCROPROISTATE Clear DIC preprocess crop ROI state and controls.

    dic_preprocess.ui.clearCropRoi( ...
        S.cropRoiListeners, S.cropRoiTop, S.cropRoiBottom);
    S.cropRoiListeners = {};
    S.cropRoiTop = [];
    S.cropRoiBottom = [];
    controls.btnApplyCrop.Enable = 'off';
    controls.btnCancelCrop.Enable = 'off';
end
