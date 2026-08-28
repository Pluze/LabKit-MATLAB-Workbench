function output = buildExportTable(summary, imageName)
%BUILDEXPORTTABLE Add source identity to a measured ROI result table.
%
% Usage:
%   output = roi_analyzer.resultFiles.buildExportTable(summary, imageName)
%
% Description:
%   Creates the stable CSV payload for one measured image. Values and ROI
%   geometry are copied from the supplied analysis table without recomputing
%   or normalizing them.
%
% Inputs:
%   summary - Table returned by roi_analyzer.analysisRun.measureImage.
%   imageName - Nonempty scalar display filename. Paths are not accepted as
%       a separate field and are not written to the result.
%
% Outputs:
%   output - summary with Image inserted as the first string column.
%
% Errors:
%   roi_analyzer:resultFiles:InvalidResult - summary is not a table or
%       imageName is empty.
%
% Example:
%   roi = roi_analyzer.roiLibrary.emptyRoi();
%   roi.id = "roi-1"; roi.name = "ROI 1"; roi.position = [1 1 2 2];
%   measured = roi_analyzer.analysisRun.measureImage(ones(3), roi);
%   output = roi_analyzer.resultFiles.buildExportTable( ...
%       measured.summary, "sample.png");
%   assert(output.Image(1) == "sample.png")
%
% See also roi_analyzer.analysisRun.measureImage
if ~istable(summary) || strlength(string(imageName)) == 0 || ...
        ~isscalar(string(imageName))
    error("roi_analyzer:resultFiles:InvalidResult", ...
        "A result table and nonempty image name are required.");
end
output = summary;
output.Image = repmat(string(imageName), height(output), 1);
output = movevars(output, "Image", "Before", 1);
end
