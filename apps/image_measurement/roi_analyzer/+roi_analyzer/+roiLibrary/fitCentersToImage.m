function [centers, fits] = fitCentersToImage(centers, rois, templates, imageSize)
%FITCENTERSTOIMAGE Translate an ROI group into an image without distortion.
centers = double(centers);
minimum = zeros(numel(rois), 2);
maximum = zeros(numel(rois), 2);
for index = 1:numel(rois)
    match = find(string({templates.id}) == string(rois(index).templateId), 1);
    if isempty(match)
        fits = false;
        return
    end
    geometry = templates(match);
    sizeXY = min(double(geometry.size), [imageSize(2), imageSize(1)]);
    if geometry.shape == "Square" || geometry.shape == "Circle"
        sizeXY = repmat(min(sizeXY), 1, 2);
    end
    minimum(index, :) = 1 + (sizeXY - 1) ./ 2;
    maximum(index, :) = [imageSize(2), imageSize(1)] - (sizeXY - 1) ./ 2;
end
lower = max(minimum - centers, [], 1);
upper = min(maximum - centers, [], 1);
fits = all(lower <= upper);
if fits
    centers = centers + min(max([0 0], lower), upper);
end
end
