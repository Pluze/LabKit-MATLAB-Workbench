% DIC Postprocess UI helper. Expected caller: labkit_DICPostprocess_app.
% Inputs are the app UI registry, image data, title, and axis id. Output is
% the drawn image handle. Side effect: updates the requested preview axes.
function hImage = showImage(ui, imageData, titleText, axisId)
    hImage = labkit.ui.view.drawImage(ui, 'overlayAxes', imageData, ...
        "title", titleText, "axis", axisId);
end
