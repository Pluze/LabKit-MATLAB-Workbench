% DIC Postprocess UI helper. Expected caller: labkit_DICPostprocess_app.
% Inputs are a target axes, image data, and title. Output is the drawn image
% handle. Side effect: updates the axes.
function hImage = showImage(ax, imageData, titleText)
    hImage = labkit.ui.view.draw(ax, 'image', imageData, titleText);
end
