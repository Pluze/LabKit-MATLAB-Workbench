% Expected caller: DIC preprocess runner. Input is the file-dialog title. Output
% is the selected image path or an empty string when cancelled. Side effect:
% opens MATLAB's image file chooser.

function filepath = chooseImageFile(titleText)
%CHOOSEIMAGEFILE Prompt for a DIC preprocess image file.

    [f, p] = uigetfile( ...
        {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', 'Image files'; '*.*', 'All files'}, ...
        titleText);
    if isequal(f, 0)
        filepath = "";
    else
        filepath = string(fullfile(p, f));
    end
end
