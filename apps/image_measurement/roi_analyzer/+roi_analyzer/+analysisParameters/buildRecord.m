function record = buildRecord(project, annotation)
%BUILDRECORD Build a portable ROI analysis-parameter record.
%
% Usage:
%   record = roi_analyzer.analysisParameters.buildRecord(project, annotation)
%
% Description:
%   Captures reusable geometry templates, the current ROI definitions and
%   centers, and the optional direct ROI-ratio selection. It deliberately omits
%   image paths, pixels, cached previews, and calculated results.
%
% Inputs:
%   project - Current ROI Analyzer project scalar structure.
%   annotation - Current source annotation returned by
%       roi_analyzer.roiLibrary.annotationForSource.
%
% Outputs:
%   record - Scalar JSON-ready structure with format, formatVersion,
%       templates, rois, and ratioDenominatorRoiId.
%
% Errors:
%   roi_analyzer:analysisParameters:InvalidState - Inputs are incomplete.
%
% See also roi_analyzer.archive.writeFile
if ~isstruct(project) || ~isscalar(project) || ...
        ~isstruct(annotation) || ~isscalar(annotation) || ...
        ~isfield(project, "annotations") || ~isfield(annotation, "rois")
    error("roi_analyzer:analysisParameters:InvalidState", ...
        "Current project and ROI annotation are required.");
end
record = struct("format", "roi_analyzer.parameters", ...
    "formatVersion", 1, ...
    "templates", project.annotations.templates, ...
    "rois", annotation.rois, ...
    "ratioDenominatorRoiId", project.parameters.ratioDenominatorRoiId);
end
