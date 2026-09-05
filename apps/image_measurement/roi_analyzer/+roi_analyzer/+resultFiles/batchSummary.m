function data = batchSummary(sources, annotations, results)
%BATCHSUMMARY Prepare one bounded status row per source without expanding measurements.
% Called by presentation; full ROI/channel assembly belongs to explicit CSV export.
data = cell(numel(sources), 4);
for k = 1:numel(sources)
    source = sources(k);
    annotation = roi_analyzer.roiLibrary.annotationForSource(annotations, source.id);
    result = roi_analyzer.analysisRun.resultForSource(results.items, source.id);
    [~, name, extension] = fileparts(string(source.path));
    status = roi_analyzer.resultFiles.measurementStatus(source.id, annotation.rois, results);
    data(k, :) = {k, char(string(name) + string(extension)), char(status), height(result.summary)};
end
end
