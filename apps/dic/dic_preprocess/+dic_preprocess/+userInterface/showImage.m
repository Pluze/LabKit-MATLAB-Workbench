% Expected caller: DIC preprocess runner. Inputs are the app UI registry, a
% preview axis id, image data, and title. Output is the drawn image handle.
% Side effect: updates the requested preview axis.

function hImage = showImage(ui, axisId, imageData, titleText)
%SHOWIMAGE Draw a DIC preprocess preview image in an axes.

    hImage = labkit.ui.plot.image(ui, 'previewAxes', imageData, ...
        "title", titleText, "axis", axisId);
end
