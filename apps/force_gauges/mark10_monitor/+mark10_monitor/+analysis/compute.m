function result = compute(time_s, force_N, travel_mm, parameters, experimentType)
%COMPUTE Estimate branch stiffness and engineering Young's modulus.
%
% Inputs are finite SI-force / millimetre records. Force and travel zero
% levels define the absolute engineering stress-strain coordinates. Each
% monotonic branch is selected in branch-local displacement and fitted in
% those corrected coordinates. Stress uses N/mm^2 (= MPa).

[time_s, force_N, travel_mm] = cleanColumns(time_s, force_N, travel_mm);
validateGeometry(parameters);
[forceZero_N, travelZero_mm] = ...
    mark10_monitor.analysis.appliedZeroLevels(parameters);
force_N = force_N - forceZero_N;
travel_mm = travel_mm - travelZero_mm;
if numel(time_s) < 16
    error("mark10_monitor:analysis:InsufficientData", ...
        "At least 16 finite force/travel samples are required.");
end
segments = monotonicSegments(travel_mm);
if isempty(segments)
    error("mark10_monitor:analysis:NoSegments", ...
        "No monotonic travel branch with sufficient span was found.");
end

area_mm2 = parameters.width_mm * parameters.thickness_mm;
segmentCount = size(segments, 1);
rows = cell(segmentCount, 11);
fitCandidates = repmat(struct("strain_percent", zeros(2, 1), ...
    "stress_MPa", zeros(2, 1), "accepted", false), segmentCount, 1);
fitCount = 0;
plotStrainByBranch = cell(segmentCount, 1);
plotStressByBranch = cell(segmentCount, 1);
pointsPerBranch = max(20, floor(2000 / segmentCount));
for k = 1:segmentCount
    indices = (segments(k, 1):segments(k, 2)).';
    displacement = abs(travel_mm(indices) - travel_mm(indices(1)));
    strain = travel_mm(indices) / parameters.gaugeLength_mm;
    stress = force_N(indices) / area_mm2;
    [fit, status] = fitBranch( ...
        displacement, travel_mm(indices), strain, stress, parameters);
    phase = phaseLabel(force_N(indices), experimentType);
    rows(k, :) = {k, char(phase), time_s(indices(1)), ...
        time_s(indices(end)), fit.start_mm, fit.end_mm, fit.count, ...
        fit.stiffness_N_per_mm, fit.modulus_MPa, fit.rSquared, ...
        char(status)};
    [branchStrain, branchStress] = boundedPlotBranch( ...
        100 * strain, stress, pointsPerBranch);
    plotStrainByBranch{k} = [branchStrain; NaN];
    plotStressByBranch{k} = [branchStress; NaN];
    if all(isfinite(fit.strainLine)) && all(isfinite(fit.stressLine))
        fitCount = fitCount + 1;
        fitCandidates(fitCount) = struct( ...
            "strain_percent", 100 * fit.strainLine, ...
            "stress_MPa", fit.stressLine, "accepted", fit.accepted);
    end
end
fits = fitCandidates(1:fitCount);
plotStrain = vertcat(plotStrainByBranch{:});
plotStress = vertcat(plotStressByBranch{:});

function [x, y] = boundedPlotBranch(x, y, maximumPoints)
if numel(x) <= maximumPoints, return; end
indices = unique(round(linspace(1, numel(x), maximumPoints)));
x = x(indices);
y = y(indices);
end

moduli = cell2mat(rows(:, 9));
accepted = strcmp(rows(:, 11), "Accepted");
statsValues = moduli(accepted & isfinite(moduli));
if isempty(statsValues)
    statsValues = moduli(isfinite(moduli));
end
result = struct( ...
    "rows", {rows}, "plotStrain_percent", plotStrain, ...
    "plotStress_MPa", plotStress, "fitLines", fits, ...
    "summary", summaryText(statsValues, sum(accepted), size(rows, 1)), ...
    "segmentCount", size(rows, 1), "acceptedCount", sum(accepted));
end

function [time_s, force_N, travel_mm] = cleanColumns(time_s, force_N, travel_mm)
time_s = double(time_s(:));
force_N = double(force_N(:));
travel_mm = double(travel_mm(:));
if numel(time_s) ~= numel(force_N) || numel(time_s) ~= numel(travel_mm)
    error("mark10_monitor:analysis:MismatchedData", ...
        "Time, force, and travel vectors must have equal lengths.");
end
keep = isfinite(time_s) & isfinite(force_N) & isfinite(travel_mm);
time_s = time_s(keep);
force_N = force_N(keep);
travel_mm = travel_mm(keep);
end

function validateGeometry(p)
names = ["gaugeLength_mm", "width_mm", "thickness_mm"];
for name = names
    value = double(p.(name));
    if ~isscalar(value) || ~isfinite(value) || value <= 0
        error("mark10_monitor:analysis:InvalidGeometry", ...
            "%s must be a finite positive value in mm.", name);
    end
end
if ~logical(p.geometryConfirmed)
    error("mark10_monitor:analysis:GeometryNotConfirmed", ...
        "Review the specimen dimensions and select Geometry reviewed.");
end
end

function segments = monotonicSegments(x)
dx = diff(x);
nonzero = abs(dx(isfinite(dx) & dx ~= 0));
if isempty(nonzero)
    segments = zeros(0, 2);
    return;
end
% Fifteen percent of the median instrument step suppresses sub-resolution
% jitter without changing the retained measurements.
motionThreshold = max(1e-9, 0.15 * median(nonzero));
direction = sign(dx);
direction(abs(dx) <= motionThreshold) = 0;
for k = 2:numel(direction)
    if direction(k) == 0, direction(k) = direction(k - 1); end
end
for k = numel(direction)-1:-1:1
    if direction(k) == 0, direction(k) = direction(k + 1); end
end
changes = find(direction(1:end-1) .* direction(2:end) < 0) + 1;
bounds = [1; changes(:); numel(x)];
segmentCandidates = zeros(numel(bounds) - 1, 2);
segmentCount = 0;
minimumPoints = 8;
% A branch must span at least five observed steps; this rejects standstill
% jitter while scaling with the source resolution.
minimumSpan = max(5 * median(nonzero), 1e-6);
for k = 1:numel(bounds)-1
    first = bounds(k);
    last = bounds(k + 1);
    if last - first + 1 >= minimumPoints && ...
            abs(x(last) - x(first)) >= minimumSpan
        segmentCount = segmentCount + 1;
        segmentCandidates(segmentCount, :) = [first, last];
    end
end
segments = segmentCandidates(1:segmentCount, :);
end

function [fit, status] = fitBranch( ...
        displacement, correctedTravel, strain, stress, p)
if string(p.fitMode) == "Manual"
    low = min(p.manualStart_mm, p.manualEnd_mm);
    high = max(p.manualStart_mm, p.manualEnd_mm);
    selected = correctedTravel >= low & correctedTravel <= high;
else
    selected = automaticRegion(displacement, stress);
end
indices = find(selected);
fit = emptyFit();
% A line has two fitted coefficients. Four distinct coordinates retain two
% residual degrees of freedom without rejecting a visibly resolved sparse
% branch solely because the acquisition cadence fell below its target.
minimumFitPoints = 4;
if numel(indices) < minimumFitPoints
    status = "Need at least 4 fit points";
    return;
end
if numel(unique(displacement(indices))) < minimumFitPoints || ...
        max(displacement(indices)) - min(displacement(indices)) <= 0
    status = "Insufficient travel span";
    return;
end
x = strain(indices);
y = stress(indices);
coefficients = polyfit(x, y, 1);
predicted = polyval(coefficients, x);
residual = sum((y - predicted).^2);
total = sum((y - mean(y)).^2);
if total <= eps(max(abs(y)))
    rSquared = NaN;
else
    rSquared = 1 - residual / total;
end
stiffness = abs(coefficients(1)) * ...
    (p.width_mm * p.thickness_mm) / p.gaugeLength_mm;
fit = struct("start_mm", min(correctedTravel(indices)), ...
    "end_mm", max(correctedTravel(indices)), "count", numel(indices), ...
    "stiffness_N_per_mm", stiffness, ...
    "modulus_MPa", abs(coefficients(1)), "rSquared", rSquared, ...
    "strainLine", [min(x); max(x)], ...
    "stressLine", polyval(coefficients, [min(x); max(x)]), ...
    "accepted", isfinite(rSquared) && rSquared >= 0.95);
if fit.accepted
    status = "Accepted";
else
    status = "Review: R² < 0.95";
end
end

function selected = automaticRegion(displacement, stress)
n = numel(displacement);
selected = false(n, 1);
span = max(displacement) - min(displacement);
if n < 8 || span <= 0, return; end
starts = 0.05:0.05:0.35;
ends = 0.45:0.05:0.85;
bestScore = -Inf;
best = false(n, 1);
for lowFraction = starts
    for highFraction = ends
        if highFraction - lowFraction < 0.25, continue; end
        candidate = displacement >= lowFraction * span & ...
            displacement <= highFraction * span;
        if nnz(candidate) < 8, continue; end
        x = displacement(candidate);
        y = stress(candidate);
        c = polyfit(x, y, 1);
        prediction = polyval(c, x);
        total = sum((y - mean(y)).^2);
        if total <= eps(max(abs(y))), continue; end
        r2 = 1 - sum((y - prediction).^2) / total;
        % Prefer linearity first, then a broad region and an earlier onset.
        score = r2 + 0.02 * (highFraction - lowFraction) - ...
            0.005 * lowFraction;
        if isfinite(score) && score > bestScore
            bestScore = score;
            best = candidate;
        end
    end
end
selected = best;
end

function fit = emptyFit()
fit = struct("start_mm", NaN, "end_mm", NaN, "count", 0, ...
    "stiffness_N_per_mm", NaN, "modulus_MPa", NaN, ...
    "rSquared", NaN, "strainLine", [NaN; NaN], ...
    "stressLine", [NaN; NaN], "accepted", false);
end

function label = phaseLabel(force, experimentType)
loading = abs(force(end)) >= abs(force(1));
phase = "recovery";
if loading, phase = "loading"; end
kind = string(experimentType);
if kind == "Tension" || kind == "Compression"
    label = kind + " " + phase;
elseif kind == "Cyclic"
    % Native Mark-10 polarity is normally compression-positive.
    if median(force, "omitnan") >= 0, kind = "Compression"; else, kind = "Tension"; end
    label = kind + " " + phase;
else
    label = upper(extractBefore(phase, 2)) + extractAfter(phase, 1);
end
end

function text = summaryText(values, accepted, total)
if isempty(values)
    text = string(sprintf( ...
        'Segments: %d\nAccepted fits: %d\nNo finite modulus estimates.', ...
        total, accepted));
    return;
end
text = string(sprintf([ ...
    'Segments: %d\nAccepted fits: %d\n', ...
    'Mean E: %.6g MPa\nMedian E: %.6g MPa\n', ...
    'SD: %.6g MPa\nRange: %.6g to %.6g MPa'], ...
    total, accepted, mean(values), median(values), std(values), ...
    min(values), max(values)));
end
