% DIC Postprocess ops helper. Expected caller: labkit_DICPostprocess_app.
% Input is image data. Output is [height width]. Side effects: none.
function targetSize = imageHeightWidth(imageData)
    targetSize = [size(imageData, 1), size(imageData, 2)];
end
