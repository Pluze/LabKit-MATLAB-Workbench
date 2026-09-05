function status = measurementStatus(sourceId, rois, results)
%MEASUREMENTSTATUS Shared status policy for batch summary and CSV missing rows.
result = roi_analyzer.analysisRun.resultForSource(results.items, sourceId);
if ~isempty(result.summary)
    status = "Measured";
    return
end
status = "Not measured";
if isempty(rois), status = "No ROIs"; end
if isfield(results, "batchStatus") && ~isempty(results.batchStatus)
    match = find(results.batchStatus.SourceId == string(sourceId), 1);
    if ~isempty(match) && results.batchStatus.Status(match) ~= "Measured"
        status = results.batchStatus.Status(match);
    end
end
end

