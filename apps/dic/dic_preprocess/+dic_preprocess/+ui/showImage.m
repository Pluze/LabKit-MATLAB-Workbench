% Expected caller: DIC preprocess runner. Inputs are a target axes, image data,
% and title. Output is the drawn image handle. Side effect: updates the axes.

function hImage = showImage(ax, imageData, titleText)
%SHOWIMAGE Draw a DIC preprocess preview image in an axes.

    hImage = labkit.ui.view.draw(ax, 'image', imageData, titleText);
end
