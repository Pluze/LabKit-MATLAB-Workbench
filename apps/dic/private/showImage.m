% App-owned DIC helper extracted from labkit_DICPreprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function hImage = showImage(ax, imageData, titleText)
    hImage = labkit.ui.view.draw(ax, 'image', imageData, titleText);
end
