function summary = summarizeMetrics(metrics)
%SUMMARIZEMETRICS Compute grouped metric counts and finite means.
%
% Usage:
%   summary = response_review_stats.analysisRun.summarizeMetrics(metrics)
%
% Description:
%   Produces compact descriptive statistics from response metric rows. Groups
%   follow their first occurrence. The function performs no weighting,
%   confidence interval, hypothesis test, or outlier removal.
%
% Inputs:
%   metrics - Metric table. pairId selects groups when that variable exists;
%       otherwise SegmentName is used, and otherwise all rows belong to "all".
%       Amplitude may be named PeakToPeak or peakToPeak. SNR may be named
%       SNR_dB or snrDb.
%
% Outputs:
%   summary - Table with one row per group.
%
% Summary Columns:
%   Group - Group name in stable first-occurrence order.
%   Count - Number of input rows in the group, including rows whose metrics are
%       nonfinite.
%   MeanPeakToPeak - Arithmetic mean of finite group amplitudes, or NaN when
%       the amplitude variable is absent or has no finite values.
%   MeanSnrDb - Arithmetic mean of finite group SNR values in decibels, or NaN
%       when the SNR variable is absent or has no finite values.
%
% Failure Behavior:
%   Empty or non-table input returns one "all" row with Count=0 and NaN means.
%
% Example:
%   metrics = table(["cp"; "cp"; "ta"], [3; 5; 2], [20; 22; 10], ...
%       'VariableNames', {'pairId', 'peakToPeak', 'snrDb'});
%   summary = response_review_stats.analysisRun.summarizeMetrics(metrics);
%   assert(summary.Group(1) == "cp" && summary.MeanPeakToPeak(1) == 4)
%
% See also response_review_stats.analysisRun.measureAlignedSegments,
%   response_review_stats.analysisRun.alignSegments

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
            MeanPeakToPeak(k) = finiteMean(metrics.PeakToPeak(mask));
        elseif ismember("peakToPeak", metrics.Properties.VariableNames)
            MeanPeakToPeak(k) = finiteMean(metrics.peakToPeak(mask));
        end
        if ismember("SNR_dB", metrics.Properties.VariableNames)
            MeanSnrDb(k) = finiteMean(metrics.SNR_dB(mask));
        elseif ismember("snrDb", metrics.Properties.VariableNames)
            MeanSnrDb(k) = finiteMean(metrics.snrDb(mask));
        end
    end
    summary = table(Group, Count, MeanPeakToPeak, MeanSnrDb);
end

function value = finiteMean(values)
    % Grouped summaries retain row counts but average finite numeric support.
    value = mean(values(isfinite(values)));
end
