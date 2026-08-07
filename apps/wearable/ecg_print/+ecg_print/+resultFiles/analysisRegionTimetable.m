function region = analysisRegionTimetable(cache)
%ANALYSISREGIONTIMETABLE Build the most recent ECG ROI sample timetable.
%
% Usage:
%   region = ecg_print.resultFiles.analysisRegionTimetable(cache)
%
% Description:
%   Converts the raw and filtered signals from the most recent successful ECG
%   analysis into one timetable. Row times match the analysis and preview time
%   axis. SourceTimeSeconds retains the corresponding time in the decoded
%   source when an ROI crop restarted analysis time at zero. DetectedPeak marks
%   samples selected by the detector.
%
% Inputs:
%   cache - Scalar ECG session cache containing signal, workingSignal,
%       filteredSignal, and events from analyzeSignal.
%
% Outputs:
%   region - Timetable with AnalysisTime row times and SourceTimeSeconds,
%       RawSignal, FilteredSignal, and DetectedPeak variables. Time values are
%       seconds. Signal variables retain the decoded channel unit in
%       Properties.VariableUnits. Properties.UserData records channel, unit,
%       sample rate, and requested source range.
%
% Errors:
%   ecg_print:resultFiles:NoAnalysisRegion - No completed analysis is present.
%   ecg_print:resultFiles:MismatchedAnalysisRegion - Raw and filtered sample
%       vectors do not share one time base.
%   ecg_print:resultFiles:InvalidEventIndex - A detected event does not name a
%       sample in the current analysis region.
%
% See also ecg_print.analysisRun.analyzeSignal, timetable

    requireAnalysis(cache);
    working = cache.workingSignal;
    filtered = cache.filteredSignal;
    analysisTime = double(working.time(:));
    raw = working.values(:);
    filteredValues = filtered.values(:);
    filteredTime = double(filtered.time(:));
    if numel(raw) ~= numel(analysisTime) || ...
            numel(filteredValues) ~= numel(analysisTime) || ...
            ~isequaln(filteredTime, analysisTime)
        error("ecg_print:resultFiles:MismatchedAnalysisRegion", ...
            "Raw and filtered ECG analysis samples must share one time base.");
    end

    sourceTime = sourceTimes(cache, analysisTime);
    detectedPeak = false(numel(analysisTime), 1);
    if isfield(cache, "events") && ~isempty(cache.events) && ...
            isfield(cache.events, "index")
        indices = double(cache.events.index(:));
        if any(~isfinite(indices) | indices ~= round(indices) | ...
                indices < 1 | indices > numel(analysisTime))
            error("ecg_print:resultFiles:InvalidEventIndex", ...
                "Detected ECG events must index the current analysis region.");
        end
        detectedPeak(indices) = true;
    end

    region = timetable(seconds(analysisTime), sourceTime, raw, ...
        filteredValues, detectedPeak, VariableNames={ ...
        'SourceTimeSeconds', 'RawSignal', 'FilteredSignal', 'DetectedPeak'});
    region.Properties.DimensionNames{1} = 'AnalysisTime';
    unit = signalText(working, "unit");
    region.Properties.VariableUnits = {'s', char(unit), char(unit), ''};
    region.Properties.Description = ...
        "Samples from the most recent ECG Print analysis region";
    region.Properties.UserData = struct( ...
        "Channel", signalText(working, "displayName"), ...
        "SignalUnit", unit, ...
        "SampleRateHz", double(working.fs), ...
        "RequestedSourceTimeRangeSeconds", requestedRange(working, sourceTime));
end

function requireAnalysis(cache)
    if ~isstruct(cache) || ~isscalar(cache) || ...
            ~all(isfield(cache, ["workingSignal", "filteredSignal"])) || ...
            isempty(cache.workingSignal) || isempty(cache.filteredSignal)
        error("ecg_print:resultFiles:NoAnalysisRegion", ...
            "Analyze an ECG signal before exporting its current region.");
    end
end

function sourceTime = sourceTimes(cache, analysisTime)
    sourceTime = analysisTime;
    working = cache.workingSignal;
    if ~isfield(working, "metadata") || ...
            ~isfield(working.metadata, "cropTimeRangeSec") || ...
            ~isfield(cache, "signal") || isempty(cache.signal)
        return;
    end
    range = double(working.metadata.cropTimeRangeSec(:).');
    originalTime = double(cache.signal.time(:));
    keep = originalTime >= range(1) & originalTime <= range(2);
    selected = originalTime(keep);
    if numel(selected) == numel(analysisTime)
        sourceTime = selected;
    end
end

function range = requestedRange(signal, sourceTime)
    if isfield(signal, "metadata") && ...
            isfield(signal.metadata, "cropTimeRangeSec")
        range = double(signal.metadata.cropTimeRangeSec(:).');
    elseif isempty(sourceTime)
        range = zeros(1, 0);
    else
        range = [sourceTime(1) sourceTime(end)];
    end
end

function value = signalText(signal, field)
    value = "";
    if isfield(signal, field)
        candidate = string(signal.(field));
        if isscalar(candidate) && ~ismissing(candidate)
            value = candidate;
        end
    end
end
