function result = measureImage(imageData, rois, ratioDenominatorRoiId)
%MEASUREIMAGE Calculate channel-wise pixel statistics for image ROIs.
%
% Usage:
%   result = roi_analyzer.analysisRun.measureImage(imageData, rois)
%   result = roi_analyzer.analysisRun.measureImage( ...
%       imageData, rois, ratioDenominatorRoiId)
%
% Description:
%   Measures each rectangle, square, or circular ROI against the original
%   numeric pixels. Scalar images expose an Intensity channel. RGB images
%   expose the original Red, Green, and Blue channels. Nonfinite values are
%   excluded independently from each channel. Every reported value is derived
%   directly from those pixels or from the selected ROI mean ratio.
%
% Inputs:
%   imageData - Nonempty numeric or logical H-by-W scalar image, or H-by-W-by-3
%       RGB image. Integer values retain their stored numeric scale.
%   rois - Structure array with id, name, shape, and position fields. shape is
%       Rectangle, Square, or Circle. position is [x y width height] in
%       one-based source pixel coordinates.
%   ratioDenominatorRoiId - Optional ROI id. Each row's mean is divided by
%       this ROI's mean for the same channel. Empty disables ratios.
%       Default: "".
%
% Outputs:
%   result - Scalar structure with summary, a table containing ROI identity,
%       geometry, pixel count, sum, mean, sample standard deviation, median,
%       unscaled median absolute deviation, minimum, maximum, linearly
%       interpolated quartiles, centroid, and reference ratio; and
%       roiFingerprint, a deterministic geometry-and-reference token.
%
% Errors:
%   roi_analyzer:analysisRun:InvalidImage - Image shape or type is unsupported.
%   roi_analyzer:analysisRun:InvalidRoi - An ROI is malformed or unknown.
%
% Example:
%   roi = roi_analyzer.roiLibrary.emptyRoi();
%   roi.id = "sample"; roi.name = "Sample";
%   roi.position = [1 1 2 2];
%   result = roi_analyzer.analysisRun.measureImage([1 2; 3 4], roi);
%   assert(result.summary.Mean == 2.5)
%
% See also roi_analyzer.roiLibrary.emptyRoi
if nargin < 3
    ratioDenominatorRoiId = "";
end
validateImage(imageData);
rois = rois(:);
rowTemplate = roi_analyzer.analysisRun.emptyRow();
[channels, channelNames] = channelMatrices(imageData);
rows = repmat(rowTemplate, numel(rois) * numel(channels), 1);
rowIndex = 0;
for roiIndex = 1:numel(rois)
    roi = validateRoi(rois(roiIndex), size(imageData));
    mask = roiMask(size(imageData), roi);
    [yy, xx] = find(mask);
    for channelIndex = 1:numel(channels)
        values = double(channels{channelIndex}(mask));
        finite = isfinite(values);
        values = values(finite);
        xFinite = double(xx(finite));
        yFinite = double(yy(finite));
        stats = summarize(values);
        row = rowTemplate;
        row.RoiId = string(roi.id);
        row.RoiName = string(roi.name);
        row.Shape = string(roi.shape);
        row.Channel = channelNames(channelIndex);
        row.PixelCount = stats.count;
        row.Integrated = stats.total;
        row.Mean = stats.mean;
        row.StdDev = stats.stdDev;
        row.Median = stats.median;
        row.MAD = stats.mad;
        row.Minimum = stats.minimum;
        row.Maximum = stats.maximum;
        row.Quartile25 = stats.q25;
        row.Quartile75 = stats.q75;
        if ~isempty(xFinite)
            row.CentroidX = mean(xFinite);
            row.CentroidY = mean(yFinite);
        end
        row.X = roi.position(1);
        row.Y = roi.position(2);
        row.Width = roi.position(3);
        row.Height = roi.position(4);
        rowIndex = rowIndex + 1;
        rows(rowIndex) = row;
    end
end
summary = struct2table(rows);
if isempty(rows)
    summary = struct2table(repmat(rowTemplate, 0, 1));
end
summary.Ratio = referenceRatios(summary, string(ratioDenominatorRoiId));
result = struct("summary", summary, ...
    "roiFingerprint", fingerprint(rois, string(ratioDenominatorRoiId)));
end

function validateImage(imageData)
if isempty(imageData) || ~(isnumeric(imageData) || islogical(imageData)) || ...
        ~(ismatrix(imageData) || (ndims(imageData) == 3 && size(imageData, 3) == 3))
    error("roi_analyzer:analysisRun:InvalidImage", ...
        "Image must be a nonempty scalar-intensity or RGB numeric array.");
end
end

function roi = validateRoi(roi, imageSize)
required = ["id" "name" "shape" "position"];
if ~isstruct(roi) || ~isscalar(roi) || ...
        ~all(isfield(roi, cellstr(required))) || ...
        strlength(string(roi.id)) == 0 || strlength(string(roi.name)) == 0 || ...
        ~any(string(roi.shape) == ["Rectangle" "Square" "Circle"])
    error("roi_analyzer:analysisRun:InvalidRoi", ...
        "Every ROI requires identity, name, supported shape, and position.");
end
position = roi_analyzer.roiLibrary.normalizePosition( ...
    roi.position, roi.shape, imageSize);
if any(~isfinite(position)) || any(position(3:4) <= 0)
    error("roi_analyzer:analysisRun:InvalidRoi", ...
        "ROI position must contain finite positive geometry.");
end
roi.position = position;
end

function mask = roiMask(imageSize, roi)
height = imageSize(1);
width = imageSize(2);
[x, y] = meshgrid(1:width, 1:height);
position = roi.position;
insideBox = x >= position(1) & x <= position(1) + position(3) & ...
    y >= position(2) & y <= position(2) + position(4);
if string(roi.shape) == "Circle"
    center = position(1:2) + position(3:4) ./ 2;
    radius = position(3:4) ./ 2;
    mask = insideBox & ((x - center(1)) ./ radius(1)).^2 + ...
        ((y - center(2)) ./ radius(2)).^2 <= 1;
else
    mask = insideBox;
end
end

function [channels, names] = channelMatrices(imageData)
if ismatrix(imageData)
    channels = {double(imageData)};
    names = "Intensity";
    return
end
channels = {double(imageData(:, :, 1)), double(imageData(:, :, 2)), ...
    double(imageData(:, :, 3))};
names = ["Red" "Green" "Blue"];
end

function stats = summarize(values)
stats = struct("count", numel(values), "total", NaN, "mean", NaN, ...
    "stdDev", NaN, "median", NaN, "mad", NaN, "minimum", NaN, ...
    "maximum", NaN, "q25", NaN, "q75", NaN);
if isempty(values)
    return
end
values = sort(values(:));
stats.total = sum(values);
stats.mean = mean(values);
if isscalar(values)
    stats.stdDev = 0;
else
    stats.stdDev = std(values, 0);
end
stats.median = median(values);
stats.mad = median(abs(values - stats.median));
stats.minimum = values(1);
stats.maximum = values(end);
stats.q25 = interpolatedQuantile(values, 0.25);
stats.q75 = interpolatedQuantile(values, 0.75);
end

function value = interpolatedQuantile(sortedValues, probability)
location = 1 + (numel(sortedValues) - 1) * probability;
lower = floor(location);
upper = ceil(location);
weight = location - lower;
value = (1 - weight) * sortedValues(lower) + weight * sortedValues(upper);
end

function ratios = referenceRatios(summary, referenceRoiId)
ratios = NaN(height(summary), 1);
if strlength(referenceRoiId) == 0
    return
end
for row = 1:height(summary)
    match = summary.RoiId == referenceRoiId & ...
        summary.Channel == summary.Channel(row);
    referenceMean = summary.Mean(find(match, 1));
    if ~isempty(referenceMean) && isfinite(referenceMean) && referenceMean ~= 0
        ratios(row) = summary.Mean(row) ./ referenceMean;
    end
end
end

function token = fingerprint(rois, ratioDenominatorRoiId)
parts = strings(numel(rois), 1);
for k = 1:numel(rois)
    parts(k) = string(rois(k).id) + "|" + string(rois(k).name) + "|" + ...
        string(rois(k).shape) + "|" + ...
        join(compose("%.12g", double(rois(k).position)), ",");
end
token = "ratioDenominator=" + ratioDenominatorRoiId + ";" + ...
    join(parts, ";");
end
