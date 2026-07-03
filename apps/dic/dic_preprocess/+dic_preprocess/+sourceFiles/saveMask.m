% Expected caller: DIC preprocess runner. Inputs are the current mask image and
% loaded reference path used for default naming. Outputs are the written path
% plus a cancellation flag. Side effects: opens a save dialog and writes a PNG.

function [outfile, cancelled] = saveMask(maskImage, referencePath, fallbackFolder)
%SAVEMASK Prompt for a file and save the DIC preprocess ROI mask.

    outfile = "";
    if nargin < 3
        fallbackFolder = tempdir;
    end
    defaultName = dic_preprocess.sourceFiles.defaultMaskPath(referencePath, fallbackFolder);
    [outfile, cancelled] = labkit.ui.app.promptOutputFile( ...
        {'*.png', 'PNG mask'}, 'Save ROI mask', defaultName);
    if cancelled
        return;
    end
    dic_preprocess.resultFiles.writeMask(maskImage, outfile);
end
