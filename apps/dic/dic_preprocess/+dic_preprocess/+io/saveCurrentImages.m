% Expected caller: DIC preprocess runner. Inputs are current images and loaded
% source paths used for the default folder. Outputs are written paths plus a
% cancellation flag. Side effects: opens a folder dialog and writes two PNGs.

function [outputs, cancelled] = saveCurrentImages(referenceImage, movingImage, referencePath, movingPath)
%SAVECURRENTIMAGES Prompt for a folder and save the current DIC image pair.

    outputs = struct('referencePath', "", 'movingPath', "");
    folder = uigetdir(dic_preprocess.io.defaultSaveFolder( ...
        referencePath, movingPath), 'Select folder for current images');
    cancelled = isequal(folder, 0);
    if cancelled
        return;
    end
    outputs = dic_preprocess.export.writeCurrentImages( ...
        referenceImage, movingImage, folder);
end
