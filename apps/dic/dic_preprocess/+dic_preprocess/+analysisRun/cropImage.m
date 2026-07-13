% Expected caller: DIC preprocess crop callback and direct unit tests. Inputs
% are one image and an imcrop-style [x y width height] rectangle. Output is
% the inclusive pixel crop clamped to image bounds. Side effects: none.
function cropped = cropImage(imageData, rect)
%CROPIMAGE Crop an image using base-MATLAB indexing.

% Rectangle width and height follow MATLAB imcrop's inclusive endpoint
% convention, so [x y 10 10] selects 11-by-11 pixels when fully in bounds.

    rect = double(rect);
    if numel(rect) ~= 4 || any(~isfinite(rect))
        error('labkit_DICPreprocess_app:InvalidCropRectangle', ...
            'Crop rectangle must contain four finite values.');
    end
    firstCol = max(1, round(rect(1)));
    firstRow = max(1, round(rect(2)));
    lastCol = min(size(imageData, 2), round(rect(1) + rect(3)));
    lastRow = min(size(imageData, 1), round(rect(2) + rect(4)));
    if lastCol < firstCol || lastRow < firstRow
        error('labkit_DICPreprocess_app:EmptyCropRectangle', ...
            'Crop rectangle does not overlap the image.');
    end
    cropped = imageData(firstRow:lastRow, firstCol:lastCol, :);
end
