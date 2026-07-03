% Expected caller: labkit_ImageMatch_app and image_match package tests.
% Output is one loaded-image record with source path, display name, and RGB
% double image payload ready for deterministic reference-match operations.
function item = emptyItem()

    item = struct( ...
        'path', "", ...
        'name', "", ...
        'image', []);
end
