% DIC Postprocess IO helper. Expected caller: labkit_DICPostprocess_app.
% Input is a file-dialog title. Output is the selected image path or empty
% string. Side effect: opens MATLAB's image file chooser.
function filepath = chooseImageFile(titleText)
    [f, p] = uigetfile( ...
        {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', 'Image files'; '*.*', 'All files'}, ...
        titleText, labkit.ui.app.defaultDialogFolder("input"));
    if isequal(f, 0)
        filepath = "";
    else
        filepath = string(fullfile(p, f));
    end
end
