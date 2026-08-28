function cache = loadSource(source)
%LOADSOURCE Decode one image without changing its numeric pixel scale.
paths = labkit.app.source.paths(source);
records = labkit.image.readFiles(paths(1), struct("Normalize", false));
imageData = records(1).image;
if ~(isnumeric(imageData) || islogical(imageData)) || ...
        ~(ismatrix(imageData) || (ndims(imageData) == 3 && size(imageData, 3) == 3))
    error("roi_analyzer:sourceImages:UnsupportedImage", ...
        "ROI Analyzer supports scalar-intensity and RGB images.");
end
[preview, scale] = previewImage(imageData);
cache = struct("sourceId", string(source.id), ...
    "name", string(records(1).name), "image", imageData, ...
    "preview", preview, "previewScale", scale);
end

function [preview, scale] = previewImage(imageData)
maximumPreviewPixels = 1500000;
height = size(imageData, 1);
width = size(imageData, 2);
scale = min(1, sqrt(maximumPreviewPixels / double(height * width)));
if scale == 1
    preview = imageData;
    return
end
rows = unique(round(linspace(1, height, max(1, round(height * scale)))));
cols = unique(round(linspace(1, width, max(1, round(width * scale)))));
preview = imageData(rows, cols, :);
scale = min(numel(rows) / height, numel(cols) / width);
end
