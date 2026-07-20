% App-owned implementation for ecg_print.resultFiles.manifestSummary within the ecg_print product workflow.
function summary = manifestSummary(lastAnalysis)
%MANIFESTSUMMARY Remove per-beat table data from ECG result provenance.
% The returned scalar struct keeps compact counts and aggregate metrics that
% are JSON-safe and sufficient to interpret either exported file.
summary = struct();
if isempty(fieldnames(lastAnalysis))
    return;
end
summary = lastAnalysis;
if isfield(summary, "perSegment")
    summary = rmfield(summary, "perSegment");
end
end
