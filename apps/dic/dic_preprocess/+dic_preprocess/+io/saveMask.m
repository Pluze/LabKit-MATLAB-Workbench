% Expected caller: DIC preprocess runner. Inputs are the current mask image and
% loaded reference path used for default naming. Outputs are the written path
% plus a cancellation flag. Side effects: opens a save dialog and writes a PNG.

function [outfile, cancelled] = saveMask(maskImage, referencePath, fallbackFolder)
%SAVEMASK Prompt for a file and save the DIC preprocess ROI mask.

    outfile = "";
    if nargin < 3
        fallbackFolder = tempdir;
    end
    defaultName = dic_preprocess.io.defaultMaskPath(referencePath, fallbackFolder);
    [f, p] = uiputfile({'*.png', 'PNG mask'}, 'Save ROI mask', defaultName);
    cancelled = isequal(f, 0);
    if cancelled
        return;
    end
    outfile = string(fullfile(p, f));
    dic_preprocess.export.writeMask(maskImage, outfile);
end
