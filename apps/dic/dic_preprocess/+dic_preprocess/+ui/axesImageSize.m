% Expected caller: DIC preprocess runner. Input is a preview UIAxes handle.
% Output is the displayed image size or empty when no image is present. Side
% effects: none.

function imageSize = axesImageSize(ax)
%AXESIMAGESIZE Return image size from the first image displayed in an axes.

    imageSize = [];
    images = findobj(ax, 'Type', 'Image');
    if isempty(images)
        return;
    end
    data = images(1).CData;
    imageSize = size(data);
end
