% Expected caller: response_review_stats.run or tests. Input is a metric
% table. Output is compact descriptive statistics. No side effects.
function summary = summarizeMetrics(metrics)
%SUMMARIZEMETRICS Compute grouped metric counts and finite means.
%   summary = response_review_stats.analysisRun.summarizeMetrics(metrics)
%   accepts a metric table. Rows group by pairId when present, otherwise by
%   SegmentName, otherwise as "all". PeakToPeak/peakToPeak and
%   SNR_dB/snrDb spellings are accepted. The output table contains Group,
%   Count, MeanPeakToPeak, and MeanSnrDb. Empty/non-table input returns one
%   "all" row with count zero and NaN means. Non-finite metrics are omitted.
%   No inferential statistics or weighting are applied.

    if ~istable(metrics) || height(metrics) == 0
        summary = table("all", 0, NaN, NaN, ...
            'VariableNames', {'Group', 'Count', 'MeanPeakToPeak', 'MeanSnrDb'});
        return;
    end

    if ismember("pairId", metrics.Properties.VariableNames)
        groupValues = string(metrics.pairId);
    elseif ismember("SegmentName", metrics.Properties.VariableNames)
        groupValues = string(metrics.SegmentName);
    else
        groupValues = repmat("all", height(metrics), 1);
    end
    groups = unique(groupValues, "stable");
    Group = groups(:);
    Count = zeros(numel(groups), 1);
    MeanPeakToPeak = NaN(numel(groups), 1);
    MeanSnrDb = NaN(numel(groups), 1);
    for k = 1:numel(groups)
        mask = groupValues == groups(k);
        Count(k) = sum(mask);
        if ismember("PeakToPeak", metrics.Properties.VariableNames)
            MeanPeakToPeak(k) = mean(metrics.PeakToPeak(mask), "omitnan");
        elseif ismember("peakToPeak", metrics.Properties.VariableNames)
            MeanPeakToPeak(k) = mean(metrics.peakToPeak(mask), "omitnan");
        end
        if ismember("SNR_dB", metrics.Properties.VariableNames)
            MeanSnrDb(k) = mean(metrics.SNR_dB(mask), "omitnan");
        elseif ismember("snrDb", metrics.Properties.VariableNames)
            MeanSnrDb(k) = mean(metrics.snrDb(mask), "omitnan");
        end
    end
    summary = table(Group, Count, MeanPeakToPeak, MeanSnrDb);
end
