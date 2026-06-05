% App-owned focus-stack file-dialog filter helper. Expected caller:
% labkit_FocusStack_app open-files callback. Output is the uigetfile filter
% cell array. This helper has no side effects.
function filter = imageDialogFilter()
%IMAGEDIALOGFILTER Return the supported focus image dialog filter.

    filter = {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', ...
        'Image files (*.png, *.jpg, *.jpeg, *.tif, *.tiff, *.bmp)'};
end
