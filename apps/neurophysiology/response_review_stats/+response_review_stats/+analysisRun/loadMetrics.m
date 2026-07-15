% Expected callers: Runtime V2 session creation and definition actions. Input
% is one analysis JSON or segment CSV path plus metric windows. Outputs are
% the rebuildable metric, summary, and aligned-signal caches.
function [metrics, summary, aligned] = loadMetrics(filepath, parameters)
    [~, ~, extension] = fileparts(char(filepath));
    aligned = [];
    if strcmpi(extension, ".json")
        payload = jsondecode(fileread(char(filepath)));
        metrics = metricsFromAnalysisPayload(payload);
    else
        source = readtable(char(filepath));
        segments = response_review_stats.sourceFiles.parseSegmentTable(source);
        aligned = response_review_stats.analysisRun.alignSegments( ...
            segments, parameters);
        metrics = response_review_stats.analysisRun.measureAlignedSegments( ...
            aligned, parameters);
    end
    summary = response_review_stats.analysisRun.summarizeMetrics(metrics);
end

function metrics = metricsFromAnalysisPayload(payload)
    if isfield(payload, "metrics") && isstruct(payload.metrics)
        metrics = struct2table(payload.metrics);
    else
        metrics = table();
    end
    if height(metrics) == 0
        return;
    end
    variables = string(metrics.Properties.VariableNames);
    for k = 1:numel(variables)
        if iscell(metrics.(variables(k)))
            try
                metrics.(variables(k)) = string(metrics.(variables(k)));
            catch
            end
        end
    end
end
