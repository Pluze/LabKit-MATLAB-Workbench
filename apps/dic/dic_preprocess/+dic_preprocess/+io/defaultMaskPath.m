% Expected caller: DIC preprocess runner and direct unit tests. Inputs are the
% reference image path plus an optional fallback folder. Output is the default
% mask file path shown by the save dialog. Side effects: none.

function filepath = defaultMaskPath(referencePath, fallbackFolder)
%DEFAULTMASKPATH Build the default DIC preprocess ROI mask path.

    if nargin < 2 || strlength(string(fallbackFolder)) == 0
        fallbackFolder = pwd;
    end

    [folder, name] = fileparts(char(referencePath));
    if isempty(folder)
        folder = char(fallbackFolder);
    end
    filepath = fullfile(folder, [name '_roi_mask.png']);
end
