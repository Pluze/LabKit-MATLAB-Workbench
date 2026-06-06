% Expected caller: DIC preprocess runner. Inputs are crop ROI listeners and
% graphics handles. Side effect: deletes valid listener/graphics handles.

function clearCropRoi(listeners, topRoi, bottomRoi)
%CLEARCROPROI Delete DIC preprocess crop ROI handles.

    for iListener = 1:numel(listeners)
        dic_preprocess.ui.deleteIfValid(listeners{iListener});
    end
    dic_preprocess.ui.deleteIfValid(topRoi);
    dic_preprocess.ui.deleteIfValid(bottomRoi);
end
