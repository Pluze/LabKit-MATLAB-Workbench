% Expected caller: labkit_ImageEnhance_app and image_enhance package tests.
% Output is one loaded-image record with source path, display name, and RGB
% double image payload ready for deterministic enhancement operations.
function item = emptyItem()

    item = struct( ...
        'path', "", ...
        'name', "", ...
        'image', []);
end
