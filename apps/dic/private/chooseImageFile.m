% App-owned DIC helper extracted from labkit_DICPreprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function filepath = chooseImageFile(titleText)
    [f, p] = uigetfile( ...
        {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', 'Image files'; '*.*', 'All files'}, ...
        titleText);
    if isequal(f, 0)
        filepath = "";
    else
        filepath = string(fullfile(p, f));
    end
end
