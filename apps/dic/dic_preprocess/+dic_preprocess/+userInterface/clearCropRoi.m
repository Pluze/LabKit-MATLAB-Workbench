% Expected caller: DIC preprocess runner. Inputs are crop ROI listeners and
% graphics handles. Side effect: deletes valid listener/graphics handles.

function clearCropRoi(listeners, topRoi, bottomRoi)
%CLEARCROPROI Delete DIC preprocess crop ROI handles.

    for iListener = 1:numel(listeners)
        dic_preprocess.userInterface.deleteIfValid(listeners{iListener});
    end
    if isstruct(topRoi) && isfield(topRoi, 'delete')
        topRoi.delete();
    else
        dic_preprocess.userInterface.deleteIfValid(topRoi);
    end
    dic_preprocess.userInterface.deleteIfValid(bottomRoi);
end
