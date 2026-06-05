% App-owned DIC helper extracted from labkit_DICPreprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function imageSize = axesImageSize(ax)
    imageSize = [];
    images = findobj(ax, 'Type', 'Image');
    if isempty(images)
        return;
    end
    data = images(1).CData;
    imageSize = size(data);
end
