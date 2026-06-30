% Expected caller: DIC preprocess runner. Inputs are current images and loaded
% source paths used for the default folder. Outputs are written paths plus a
% cancellation flag. Side effects: prompts for a folder and writes two PNGs.

function [outputs, cancelled] = saveCurrentImages(referenceImage, movingImage, referencePath, movingPath, fallbackFolder)
%SAVECURRENTIMAGES Prompt for a folder and save the current DIC image pair.

    outputs = struct('referencePath', "", 'movingPath', "");
    if nargin < 5
        fallbackFolder = tempdir;
    end
    [folder, cancelled] = labkit.ui.app.promptOutputFolder( ...
        'Select folder for current images', ...
        dic_preprocess.io.defaultSaveFolder(referencePath, movingPath, fallbackFolder));
    if cancelled
        return;
    end
    outputs = dic_preprocess.export.writeCurrentImages( ...
        referenceImage, movingImage, folder);
end
