function cropped = cropImage(imageData, rect)
%CROPIMAGE Crop an image using base-MATLAB indexing.
%
% Usage:
%   cropped = dic_preprocess.analysisRun.cropImage(imageData, rect)
%
% Inputs:
%   imageData - Numeric two-dimensional or multichannel image.
%   rect - Four finite values [x y width height] in image-pixel coordinates.
%       Values are rounded to pixel indices and limited to image bounds.
%
% Outputs:
%   cropped - Inclusive pixel crop preserving input class and channels.
%
% Description:
%   Width and height follow MATLAB imcrop's inclusive-endpoint convention:
%   [x y 10 10] selects 11-by-11 pixels when fully inside the image. A partially
%   overlapping rectangle is clipped; a rectangle with no overlap errors.
%
% Errors:
%   labkit_DICPreprocess_app:InvalidCropRectangle - rect does not contain four
%       finite numeric values.
%   labkit_DICPreprocess_app:EmptyCropRectangle - The rounded rectangle does
%       not overlap imageData.
%
% Example:
%   imageData = reshape(1:100, 10, 10);
%   cropped = dic_preprocess.analysisRun.cropImage(imageData, [2 3 4 2]);
%   assert(isequal(size(cropped), [3 5]))
%
% See also dic_preprocess.analysisRun.applyRigidTransform

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
