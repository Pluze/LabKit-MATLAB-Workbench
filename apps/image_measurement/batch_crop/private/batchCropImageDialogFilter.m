% App-owned image dialog filter helper. Expected caller: batch-crop app open
% callback. Output is a uigetfile filter cell array and has no side effects.
function filter = batchCropImageDialogFilter()
%BATCHCROPIMAGEDIALOGFILTER Return supported image file dialog filters.

    filter = {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', ...
        'Image files (*.png, *.jpg, *.jpeg, *.tif, *.tiff, *.bmp)'};
end
