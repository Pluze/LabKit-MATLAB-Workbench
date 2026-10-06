function estimate = estimateOnset(time_s, force_N, travel_mm, parameters, experimentType)
%ESTIMATEONSET Suggest effective length at sustained first loading.
% Uses a reviewed closed-fixture travel reference and unloaded force zero.
% This threshold estimate is a review candidate, not an exact contact fit.
time_s = double(time_s(:));
force_N = double(force_N(:));
travel_mm = double(travel_mm(:));
if numel(time_s) < 16 || numel(force_N) ~= numel(time_s) || ...
        numel(travel_mm) ~= numel(time_s) || any(~isfinite(time_s)) || ...
        any(~isfinite(force_N)) || any(~isfinite(travel_mm)) || any(diff(time_s) <= 0)
    error("mark10_monitor:analysis:InvalidEstimateData", ...
        "Length estimation needs at least 16 finite, time-ordered samples.");
end
sourceIndices = (1:numel(time_s)).';
excludedCount = 0;
if parameters.excludeGlitches
    excluded = mark10_monitor.analysis.detectGlitches(force_N, travel_mm);
    excludedCount = nnz(excluded);
    time_s(excluded) = [];
    force_N(excluded) = [];
    travel_mm(excluded) = [];
    sourceIndices(excluded) = [];
end
if numel(time_s) < 16
    error("mark10_monitor:analysis:InvalidEstimateData", ...
        "Too few samples remain after glitch exclusion.");
end
threshold_N = double(parameters.onsetThreshold_N);
if ~isscalar(threshold_N) || ~isfinite(threshold_N) || threshold_N <= 0
    error("mark10_monitor:analysis:InvalidEstimateThreshold", ...
        "Load threshold must be finite and positive in N.");
end
kind = string(experimentType);
if ~isscalar(kind) || ~any(kind == mark10_monitor.analysis.experimentTypes())
    error("mark10_monitor:analysis:InvalidExperimentType", ...
        "Select Tension, Compression, or Cyclic.");
end
[forceZero, travelZero] = mark10_monitor.analysis.appliedZeroLevels(parameters);
force = force_N - forceZero;
gap = travel_mm - travelZero;
% Half a second supplies an unloaded noise sample without absorbing the
% subsequent loading ramp. Six robust sigma rejects ordinary baseline noise.
baselineDuration_s = 0.5;
noiseMultiplier = 6;
normalMadScale = 1.4826;
baseline = time_s <= time_s(1) + baselineDuration_s;
if nnz(baseline) < 8 || all(baseline)
    error("mark10_monitor:analysis:InvalidEstimateData", ...
        "Record at least 0.5 s unloaded with eight samples before loading.");
end
baselineForce = median(force(baseline));
noise = normalMadScale * median(abs(force(baseline) - baselineForce));
threshold_N = max(threshold_N, noiseMultiplier * noise);
if abs(baselineForce) > threshold_N
    error("mark10_monitor:analysis:UnloadedStartRequired", ...
        "The recording must start unloaded; review force zero or enter length manually.");
end
% A 0.2 s run and four samples reject isolated serial spikes. A 0.5 s motion
% window accommodates quantized travel without treating a stationary spike
% as contact. A long acquisition gap cannot count as sustained loading.
hold_s = 0.2;
motionWindow_s = 0.5;
minimumRunSamples = 4;
maximumGap_s = max(hold_s, 3 * median(diff(time_s)));
for index = find(~baseline, 1):numel(time_s)
    polarity = 1;
    if kind == "Compression" || (kind == "Cyclic" && force(index) < 0)
        polarity = -1;
    end
    if polarity * force(index) <= threshold_N || ...
            polarity * force(index - 1) > threshold_N
        continue;
    end
    last = find(time_s >= time_s(index) + hold_s, 1);
    if isempty(last), break; end
    firstMotion = find(time_s >= time_s(index) - motionWindow_s, 1);
    loaded = polarity * force(index:last) > threshold_N;
    if last-index+1 < minimumRunSamples || ~all(loaded) || ...
            any(diff(time_s(index:last)) > maximumGap_s) || ...
            polarity * (gap(last) - gap(firstMotion)) <= 0 || gap(index) <= 0
        continue;
    end
    estimate = struct("length_mm", gap(index), "sampleIndex", sourceIndices(index), ...
        "time_s", time_s(index), "force_N", force(index), ...
        "threshold_N", threshold_N, "hold_s", hold_s, ...
        "previousGap_mm", gap(index-1), "excludedCount", excludedCount);
    return;
end
error("mark10_monitor:analysis:NoLoadOnset", ...
    "No sustained loading onset found. Review the threshold, force/travel zeros and test type, or enter length manually.");
end
