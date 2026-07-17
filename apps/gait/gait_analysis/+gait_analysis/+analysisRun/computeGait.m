function result = computeGait(pose, opts)
%COMPUTEGAIT Calculate joint, segment, swing, and step-quality measurements.
%
% Usage:
%   result = gait_analysis.analysisRun.computeGait(pose, opts)
%
% Description:
%   Analyzes named two-dimensional pose coordinates without opening the app.
%   The function maps five anatomical roles to source points, smooths their
%   coordinates, calculates joint angles and segment lengths, detects repeated
%   active swings, evaluates each swing against quality thresholds, and
%   returns the same four tables used by app preview and CSV export.
%
% Inputs:
%   pose - Scalar normalized pose structure, normally returned by
%       gait_analysis.sourceFiles.readPoseFile. Required fields are coords, an
%       F-by-P-by-2 numeric array of [x y] image coordinates, and pointNames,
%       a P-element text vector. Optional frameIndex and time vectors must have
%       F elements. unitName labels coordinates that are already physical.
%       sourceFormat is copied into the summary table.
%   opts - Scalar option structure. Start with
%       gait_analysis.analysisRun.defaultOptions; missing fields use those defaults.
%
% Options:
%   iliacPoint - Case-insensitive point name assigned to the iliac role.
%       Default: "iliac".
%   hipPoint - Point name assigned to the hip role. Default: "hip".
%   kneePoint - Point name assigned to the knee role. Default: "knee".
%   anklePoint - Point name assigned to the ankle role. Default: "ankle".
%   footPoint - Point name used for event detection and step length.
%       Default: "foot".
%   frameRate - Frames per second used only when pose.time has no finite values.
%       Current Video Marker projects supply this value from embedded video
%       metadata. Zero leaves time_s as NaN. Default: 0.
%   pixelsPerUnit - Positive pixel density for physical output. Distances and
%       scaled coordinates are divided by this value. When invalid, pose.unitName
%       is retained at scale 1 when present; otherwise output uses pixels.
%       Default: 1.
%   unitName - Label used with a valid pixelsPerUnit. Default: "px".
%   originAtFirstFrameFirstPoint - When true, coordinateTable subtracts the
%       first point's first-frame coordinate from every scaled point. Raw pixel
%       columns are unchanged. Default: false.
%   smoothWindow - Requested centered smoothing span in frames, rounded to an
%       integer of at least one. The effective odd span is
%       2*floor((smoothWindow-1)/2)+1. Finite values are averaged separately for
%       each point and axis. Default: 5.
%   detectionProminence - Minimum foot-X peak prominence in source coordinate
%       units. Default: 20, preserving the legacy treadmill workflow threshold.
%   detectionMinHeightSigma - A lift-off peak must be at least
%       mean(foot X)-value*std(foot X). Default: 2, preserving the legacy
%       treadmill peak-height floor.
%   minLiftOffIntervalSeconds - Minimum separation between lift-off peaks. It is
%       converted to frames from source time/frame rate. Default: 0.2 seconds.
%   minSwingFrames - Minimum accepted lift-off-to-landing span. It is also the
%       event separation fallback when source timing is unavailable. Default: 3.
%   maxSwingFrames - Maximum accepted inclusive lift-off-to-landing span.
%       Default: 300.
%   minStepLength - Minimum accepted two-dimensional foot endpoint displacement.
%       Default: 1.
%   maxHipTranslation - Maximum accepted hip endpoint displacement in output units.
%       Default: 1000000, which normally leaves this check inactive.
%
% Event Detection:
%   The detection trace is smoothed foot X. A lift-off candidate is a local
%   maximum meeting detectionProminence; nearby candidates retain the higher
%   peak. Each lift-off is independently paired with the following foot-X
%   minimum before the next lift-off, or before the recording ends. Therefore
%   a completed final swing is retained even without a later lift-off. These
%   are kinematic treadmill events, not force-plate contact measurements.
%
% Measurements:
%   Hip, knee, and ankle angles are the unsigned angles from 0 to 180 degrees
%   between the two adjacent segment vectors. A zero-length or nonfinite segment
%   produces NaN. Segment lengths are Euclidean distances. For each cycle,
%   Step length and each point translation are Euclidean endpoint
%   displacements from lift-off to landing. Range of motion is the finite
%   maximum-minus-minimum joint angle within that swing. When a
%   next lift-off exists, cycle time, stance time, cadence, and duty factor are
%   also reported; the final complete swing may legitimately lack them.
%
% Outputs:
%   result - Scalar structure containing status, normalized options, events,
%       and four tables.
%
% Result Fields:
%   ok, message - true and "Analysis complete" after successful calculation.
%   options - Effective options after defaults, scalar cleanup, and rounding.
%   events - Structure with paired liftOffFrames and landingFrames, peak
%       prominence, the foot-X detectionSignal, and footRelativeX diagnostic.
%   frameTable - One row per frame. It contains frame/time/step membership,
%       landing and lift-off flags, coordinate unit, three joint angles, four
%       segment lengths, and scaled <point>_x/<point>_y columns.
%   coordinateTable - One row per frame with frame/time and origin metadata,
%       raw <point>__x_px/<point>__y_px columns, and scaled, optionally shifted
%       <point>__x/<point>__y columns. The unshifted origin is [0 0] in pixel
%       coordinates rather than the center of pixel [1 1].
%   stepTable - One row per paired lift-off-to-landing swing. It contains
%       validity and reason, event frames, swing/cycle/stance timing, cadence,
%       duty factor, two-dimensional step length and point translations, three
%       joint extrema/ranges of motion, and recording-wide joint extrema.
%       invalid_reason is "ok", "duration_out_of_range",
%       "step_length_too_small", or "hip_translation_too_large".
%   summaryTable - Metric/value text table reporting source geometry, detected
%       and valid step counts, mean valid-swing time and step length, and global
%       finite joint-angle extrema.
%
% Errors:
%   labkit_GaitAnalysis_app:NoPoseData - pose has no nonempty coords field.
%   labkit_GaitAnalysis_app:MissingRolePoint - A configured role name is absent
%       from pose.pointNames.
%
% Example:
%   frame = (1:12).';
%   footX = [-2; -3; -1; 2; 4; -3; -1; 2; 4; -3; -1; 1];
%   pose = struct("coords", NaN(12, 5, 2), ...
%       "pointNames", ["iliac"; "hip"; "knee"; "ankle"; "foot"], ...
%       "frameIndex", frame, "time", (frame-1)/30, ...
%       "unitName", "px", "sourceFormat", "synthetic");
%   pose.coords(:, :, 1) = [-2*ones(12,1), zeros(12,1), ...
%       ones(12,1), 2*ones(12,1), footX];
%   pose.coords(:, :, 2) = repmat([8 6 4 2 0], 12, 1);
%   opts = gait_analysis.analysisRun.defaultOptions();
%   opts.smoothWindow = 1;
%   opts.detectionProminence = 2;
%   opts.minLiftOffIntervalSeconds = 0.1;
%   result = gait_analysis.analysisRun.computeGait(pose, opts);
%   assert(result.ok && height(result.stepTable) == 2)
%
% See also gait_analysis.sourceFiles.readPoseFile,
%   gait_analysis.analysisRun.defaultOptions,
%   video_marker.coordinateExport.buildTable

    if ~isstruct(pose) || ~isfield(pose, "coords") || isempty(pose.coords)
        error('labkit_GaitAnalysis_app:NoPoseData', ...
            'Load pose coordinates before running gait analysis.');
    end
    opts = normalizeOptions(opts);
    role = resolveRoles(pose.pointNames, opts);
    coords = double(pose.coords);
    frameCount = size(coords, 1);
    frameIndex = frameIndexVector(pose, frameCount);
    time = timeVector(pose, opts, frameCount);
    [scale, coordinateUnit] = coordinateScale(pose, opts);
    smoothCoords = smoothCoordinates(coords, opts.smoothWindow);

    angles = computeJointAngles(smoothCoords, role);
    segments = computeSegmentLengths(smoothCoords, role, scale);
    events = detectStepEvents(smoothCoords, role, opts, time);
    stepPayload = buildStepPayload(smoothCoords, angles, events, time, ...
        opts, role, scale);

    result = struct();
    result.ok = true;
    result.message = "Analysis complete";
    result.options = opts;
    result.events = events;
    result.frameTable = buildFrameTable(frameIndex, time, smoothCoords, ...
        pose.pointNames, angles, segments, stepPayload.frameStepIndex, ...
        events, scale, coordinateUnit);
    result.coordinateTable = buildCoordinateExportTable(frameIndex, time, ...
        smoothCoords, pose.pointNames, opts, scale, coordinateUnit);
    result.stepTable = buildStepTable(stepPayload, angles, coordinateUnit);
    result.summaryTable = buildSummaryTable(result, pose, coordinateUnit);
end

function opts = normalizeOptions(opts)
    defaults = gait_analysis.analysisRun.defaultOptions();
    names = string(fieldnames(defaults));
    for k = 1:numel(names)
        name = char(names(k));
        if ~isstruct(opts) || ~isfield(opts, name)
            opts.(name) = defaults.(name);
        end
    end
    opts.iliacPoint = string(opts.iliacPoint);
    opts.hipPoint = string(opts.hipPoint);
    opts.kneePoint = string(opts.kneePoint);
    opts.anklePoint = string(opts.anklePoint);
    opts.footPoint = string(opts.footPoint);
    opts.frameRate = finiteScalar(opts.frameRate, NaN, 0, Inf, false);
    opts.pixelsPerUnit = finiteScalar(opts.pixelsPerUnit, NaN, 0, Inf, false);
    opts.unitName = string(opts.unitName);
    opts.originAtFirstFrameFirstPoint = logicalScalar(opts.originAtFirstFrameFirstPoint);
    opts.smoothWindow = finiteScalar(opts.smoothWindow, 5, 1, Inf, true);
    opts.detectionProminence = finiteScalar( ...
        opts.detectionProminence, 20, 0, Inf, false);
    opts.detectionMinHeightSigma = finiteScalar( ...
        opts.detectionMinHeightSigma, 2, 0, Inf, false);
    opts.minLiftOffIntervalSeconds = finiteScalar( ...
        opts.minLiftOffIntervalSeconds, 0.2, 0, Inf, false);
    opts.minSwingFrames = finiteScalar(opts.minSwingFrames, 3, 1, Inf, true);
    opts.maxSwingFrames = finiteScalar(opts.maxSwingFrames, Inf, 1, Inf, true);
    opts.minStepLength = finiteScalar(opts.minStepLength, 1, 0, Inf, false);
    opts.maxHipTranslation = finiteScalar( ...
        opts.maxHipTranslation, Inf, 0, Inf, false);
end

function value = logicalScalar(value)
    if isempty(value)
        value = false;
    elseif islogical(value) || isnumeric(value)
        value = logical(value(1));
    else
        text = lower(string(value));
        value = text == "true" || text == "1" || text == "on";
    end
end

function value = finiteScalar(value, fallback, lowerBound, upperBound, makeInteger)
    value = double(value);
    if ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
    if isfinite(value)
        value = min(max(value, lowerBound), upperBound);
    end
    if makeInteger && isfinite(value)
        value = round(value);
    end
end

function role = resolveRoles(pointNames, opts)
    role = struct();
    role.iliac = pointIndex(pointNames, opts.iliacPoint);
    role.hip = pointIndex(pointNames, opts.hipPoint);
    role.knee = pointIndex(pointNames, opts.kneePoint);
    role.ankle = pointIndex(pointNames, opts.anklePoint);
    role.foot = pointIndex(pointNames, opts.footPoint);
    role.pointNames = ["iliac", "hip", "knee", "ankle", "foot"];
    role.pointIndices = [role.iliac, role.hip, role.knee, role.ankle, role.foot];
end

function idx = pointIndex(pointNames, requested)
    idx = find(lower(string(pointNames(:))) == lower(string(requested)), 1);
    if isempty(idx)
        error('labkit_GaitAnalysis_app:MissingRolePoint', ...
            'Required gait point "%s" is missing from the pose data.', requested);
    end
end

function frames = frameIndexVector(pose, frameCount)
    if isfield(pose, "frameIndex") && numel(pose.frameIndex) == frameCount
        frames = double(pose.frameIndex(:));
    else
        frames = (1:frameCount).';
    end
end

function time = timeVector(pose, opts, frameCount)
    if isfield(pose, "time") && numel(pose.time) == frameCount && ...
            any(isfinite(double(pose.time(:))))
        time = double(pose.time(:));
    elseif isfinite(opts.frameRate) && opts.frameRate > 0
        time = ((1:frameCount).' - 1) ./ opts.frameRate;
    else
        time = NaN(frameCount, 1);
    end
end

function [scale, coordinateUnit] = coordinateScale(pose, opts)
    if isfinite(opts.pixelsPerUnit) && opts.pixelsPerUnit > 0
        scale = 1 ./ opts.pixelsPerUnit;
        coordinateUnit = opts.unitName;
    elseif isfield(pose, "unitName") && strlength(string(pose.unitName)) > 0
        scale = 1;
        coordinateUnit = string(pose.unitName);
    else
        scale = 1;
        coordinateUnit = "px";
    end
end

function smoothCoords = smoothCoordinates(coords, window)
    frameCount = size(coords, 1);
    pointCount = size(coords, 2);
    smoothCoords = NaN(size(coords));
    halfWindow = floor((window - 1) / 2);
    for f = 1:frameCount
        a = max(1, f - halfWindow);
        b = min(frameCount, f + halfWindow);
        block = coords(a:b, :, :);
        for p = 1:pointCount
            for xy = 1:2
                values = block(:, p, xy);
                values = values(isfinite(values));
                if ~isempty(values)
                    smoothCoords(f, p, xy) = mean(values);
                end
            end
        end
    end
end

function angles = computeJointAngles(coords, role)
    angles = struct();
    angles.hip = jointAngle(coords(:, role.iliac, :), ...
        coords(:, role.hip, :), coords(:, role.knee, :));
    angles.knee = jointAngle(coords(:, role.hip, :), ...
        coords(:, role.knee, :), coords(:, role.ankle, :));
    angles.ankle = jointAngle(coords(:, role.knee, :), ...
        coords(:, role.ankle, :), coords(:, role.foot, :));
end

function angle = jointAngle(a, b, c)
    u = squeeze(a - b);
    v = squeeze(c - b);
    dotValue = sum(u .* v, 2);
    nu = sqrt(sum(u .* u, 2));
    nv = sqrt(sum(v .* v, 2));
    cosineValue = dotValue ./ (nu .* nv);
    cosineValue = min(max(cosineValue, -1), 1);
    angle = acosd(cosineValue);
    angle(~isfinite(nu) | ~isfinite(nv) | nu == 0 | nv == 0) = NaN;
end

function segments = computeSegmentLengths(coords, role, scale)
    segments = struct();
    segments.iliac_hip = distance(coords(:, role.iliac, :), coords(:, role.hip, :)) .* scale;
    segments.hip_knee = distance(coords(:, role.hip, :), coords(:, role.knee, :)) .* scale;
    segments.knee_ankle = distance(coords(:, role.knee, :), coords(:, role.ankle, :)) .* scale;
    segments.ankle_foot = distance(coords(:, role.ankle, :), coords(:, role.foot, :)) .* scale;
end

function d = distance(a, b)
    delta = squeeze(a - b);
    d = sqrt(sum(delta .* delta, 2));
end

function events = detectStepEvents(coords, role, opts, time)
    signal = double(coords(:, role.foot, 1));
    rate = effectiveFrameRate(time, opts.frameRate);
    if rate > 0
        minSeparation = max(1, round(rate .* opts.minLiftOffIntervalSeconds));
    else
        minSeparation = opts.minSwingFrames;
    end
    finiteSignal = signal(isfinite(signal));
    minimumPeakHeight = -Inf;
    if ~isempty(finiteSignal)
        minimumPeakHeight = mean(finiteSignal) - ...
            opts.detectionMinHeightSigma .* std(finiteSignal);
    end
    [liftOffFrames, prominence] = prominentMaxima( ...
        signal, opts.detectionProminence, minSeparation, minimumPeakHeight);
    landingFrames = zeros(size(liftOffFrames));
    keep = false(size(liftOffFrames));
    for k = 1:numel(liftOffFrames)
        first = liftOffFrames(k) + 1;
        last = numel(signal);
        if k < numel(liftOffFrames)
            last = liftOffFrames(k + 1) - 1;
        end
        if first > last
            continue;
        end
        segment = signal(first:last);
        finite = find(isfinite(segment));
        if isempty(finite)
            continue;
        end
        [~, relative] = min(segment(finite));
        landingFrames(k) = first + finite(relative) - 1;
        keep(k) = landingFrames(k) > liftOffFrames(k);
    end
    events = struct();
    events.liftOffFrames = liftOffFrames(keep);
    events.landingFrames = landingFrames(keep);
    events.detectionSignal = signal(:);
    events.footRelativeX = signal(:) - coords(:, role.hip, 1);
    events.prominence = prominence(keep);
    events.minimumPeakHeight = minimumPeakHeight;
end

function rate = effectiveFrameRate(time, configured)
    rate = 0;
    finiteTime = double(time(isfinite(time)));
    if numel(finiteTime) > 1
        intervals = diff(finiteTime);
        intervals = intervals(isfinite(intervals) & intervals > 0);
        if ~isempty(intervals)
            rate = 1 ./ median(intervals);
        end
    elseif isfinite(configured) && configured > 0
        rate = configured;
    end
end

function [frames, prominence] = prominentMaxima( ...
        values, minProminence, minSeparation, minimumHeight)
    values = double(values(:));
    candidates = zeros(numel(values), 1);
    candidateProminence = zeros(numel(values), 1);
    candidateCount = 0;
    for k = 2:numel(values)-1
        if ~isfinite(values(k)) || values(k) < minimumHeight || ...
                values(k) < values(k - 1) || ...
                values(k) <= values(k + 1)
            continue;
        end
        value = peakProminence(values, k);
        if value >= minProminence
            candidateCount = candidateCount + 1;
            candidates(candidateCount) = k;
            candidateProminence(candidateCount) = value;
        end
    end
    candidates = candidates(1:candidateCount);
    candidateProminence = candidateProminence(1:candidateCount);
    if isempty(candidates)
        frames = candidates;
        prominence = candidateProminence;
        return;
    end
    [~, order] = sort(values(candidates), "descend");
    selected = false(size(candidates));
    accepted = zeros(numel(candidates), 1);
    acceptedCount = 0;
    for index = order(:).'
        candidate = candidates(index);
        prior = accepted(1:acceptedCount);
        if acceptedCount == 0 || all(abs(candidate - prior) >= minSeparation)
            selected(index) = true;
            acceptedCount = acceptedCount + 1;
            accepted(acceptedCount) = candidate;
        end
    end
    frames = candidates(selected);
    prominence = candidateProminence(selected);
    [frames, order] = sort(frames);
    prominence = prominence(order);
end

function value = peakProminence(values, peak)
    peakValue = values(peak);
    leftLimit = 1;
    for k = peak-1:-1:1
        if isfinite(values(k)) && values(k) > peakValue
            leftLimit = k;
            break;
        end
    end
    rightLimit = numel(values);
    for k = peak+1:numel(values)
        if isfinite(values(k)) && values(k) > peakValue
            rightLimit = k;
            break;
        end
    end
    left = values(leftLimit:peak);
    right = values(peak:rightLimit);
    left = left(isfinite(left));
    right = right(isfinite(right));
    if isempty(left) || isempty(right)
        value = 0;
    else
        value = peakValue - max(min(left), min(right));
    end
end

function payload = buildStepPayload(coords, angles, events, time, opts, role, scale)
    stepCount = numel(events.liftOffFrames);
    frameCount = size(coords, 1);
    payload = struct();
    payload.liftOffFrame = zeros(stepCount, 1);
    payload.landingFrame = zeros(stepCount, 1);
    payload.stepTime = NaN(stepCount, 1);
    payload.stepLength = NaN(stepCount, 1);
    payload.cycleTime = NaN(stepCount, 1);
    payload.stanceTime = NaN(stepCount, 1);
    payload.cadence = NaN(stepCount, 1);
    payload.dutyFactor = NaN(stepCount, 1);
    payload.isValid = false(stepCount, 1);
    payload.invalidReason = strings(stepCount, 1);
    payload.translations = NaN(stepCount, numel(role.pointIndices));
    payload.rom = NaN(stepCount, 3);
    payload.angleMin = NaN(stepCount, 3);
    payload.angleMax = NaN(stepCount, 3);
    payload.frameStepIndex = zeros(frameCount, 1);

    for s = 1:stepCount
        startFrame = events.liftOffFrames(s);
        endFrame = events.landingFrames(s);
        idx = startFrame:endFrame;
        payload.liftOffFrame(s) = events.liftOffFrames(s);
        payload.landingFrame(s) = endFrame;
        payload.frameStepIndex(idx) = s;
        payload.stepTime(s) = durationForFrames(time, startFrame, endFrame);
        payload.stepLength(s) = endpointDistance( ...
            coords, startFrame, endFrame, role.foot) .* scale;
        for p = 1:numel(role.pointIndices)
            payload.translations(s, p) = endpointDistance( ...
                coords, startFrame, endFrame, role.pointIndices(p)) .* scale;
        end
        angleValues = [angles.hip(idx), angles.knee(idx), angles.ankle(idx)];
        for joint = 1:3
            payload.angleMin(s, joint) = finiteMin(angleValues(:, joint));
            payload.angleMax(s, joint) = finiteMax(angleValues(:, joint));
        end
        payload.rom(s, :) = payload.angleMax(s, :) - payload.angleMin(s, :);
        if s < stepCount
            nextLiftOff = events.liftOffFrames(s + 1);
            payload.cycleTime(s) = durationForFrames(time, startFrame, nextLiftOff);
            payload.stanceTime(s) = durationForFrames(time, endFrame, nextLiftOff);
            if isfinite(payload.cycleTime(s)) && payload.cycleTime(s) > 0
                payload.cadence(s) = 60 ./ payload.cycleTime(s);
                payload.dutyFactor(s) = payload.stanceTime(s) ./ payload.cycleTime(s);
            end
        end
        [payload.isValid(s), payload.invalidReason(s)] = validateStep( ...
            endFrame - startFrame + 1, payload.stepLength(s), ...
            payload.translations(s, 2), opts);
    end
end

function value = endpointDistance(coords, first, last, point)
    a = squeeze(coords(first, point, :));
    b = squeeze(coords(last, point, :));
    if numel(a) ~= 2 || numel(b) ~= 2 || any(~isfinite([a(:); b(:)]))
        value = NaN;
    else
        value = hypot(b(1) - a(1), b(2) - a(2));
    end
end

function value = durationForFrames(time, startFrame, endFrame)
    if numel(time) >= endFrame && isfinite(time(startFrame)) && isfinite(time(endFrame))
        value = time(endFrame) - time(startFrame);
    else
        value = NaN;
    end
end

function [tf, reason] = validateStep(frameSpan, stepLength, hipTranslation, opts)
    tf = true;
    reason = "ok";
    if frameSpan < opts.minSwingFrames || frameSpan > opts.maxSwingFrames
        tf = false;
        reason = "duration_out_of_range";
    elseif ~isfinite(stepLength) || stepLength < opts.minStepLength
        tf = false;
        reason = "step_length_too_small";
    elseif isfinite(opts.maxHipTranslation) && isfinite(hipTranslation) && ...
            hipTranslation > opts.maxHipTranslation
        tf = false;
        reason = "hip_translation_too_large";
    end
end

function T = buildFrameTable(frameIndex, time, coords, pointNames, angles, ...
        segments, frameStepIndex, events, scale, coordinateUnit)
    frameCount = numel(frameIndex);
    T = table();
    T.frame_index = frameIndex(:);
    T.time_s = time(:);
    T.step_index = frameStepIndex(:);
    T.landing_event = ismember((1:frameCount).', events.landingFrames);
    T.lift_off_event = ismember((1:frameCount).', events.liftOffFrames);
    T.coordinate_unit = repmat(string(coordinateUnit), frameCount, 1);
    T.hip_angle_deg = angles.hip(:);
    T.knee_angle_deg = angles.knee(:);
    T.ankle_angle_deg = angles.ankle(:);
    T.iliac_hip_length = segments.iliac_hip(:);
    T.hip_knee_length = segments.hip_knee(:);
    T.knee_ankle_length = segments.knee_ankle(:);
    T.ankle_foot_length = segments.ankle_foot(:);
    for p = 1:numel(pointNames)
        base = matlab.lang.makeValidName(char(pointNames(p)));
        T.([base '_x']) = coords(:, p, 1) .* scale;
        T.([base '_y']) = coords(:, p, 2) .* scale;
    end
end

function T = buildCoordinateExportTable(frameIndex, time, coords, pointNames, ...
        opts, scale, coordinateUnit)
    frameCount = numel(frameIndex);
    origin = exportOrigin(coords, pointNames, opts);
    T = table();
    T.frame_index = frameIndex(:);
    T.time_s = time(:);
    T.coordinate_unit = repmat(string(coordinateUnit), frameCount, 1);
    T.pixels_per_unit = repmat(double(opts.pixelsPerUnit), frameCount, 1);
    T.origin_mode = repmat(origin.mode, frameCount, 1);
    T.origin_point = repmat(origin.pointName, frameCount, 1);
    T.origin_x_px_value = repmat(origin.xPx, frameCount, 1);
    T.origin_y_px_value = repmat(origin.yPx, frameCount, 1);
    for p = 1:numel(pointNames)
        base = matlab.lang.makeValidName(char(pointNames(p)));
        xPx = coords(:, p, 1);
        yPx = coords(:, p, 2);
        T.([base '__x_px']) = xPx;
        T.([base '__y_px']) = yPx;
        T.([base '__x']) = (xPx - origin.xPx) .* scale;
        T.([base '__y']) = (yPx - origin.yPx) .* scale;
    end
end

function origin = exportOrigin(coords, pointNames, opts)
    origin = struct();
    if opts.originAtFirstFrameFirstPoint && ~isempty(pointNames)
        origin.mode = "first_frame_first_point";
        origin.pointName = string(pointNames(1));
        origin.xPx = coords(1, 1, 1);
        origin.yPx = coords(1, 1, 2);
    else
        origin.mode = "image_pixel_origin";
        origin.pointName = "";
        origin.xPx = 0;
        origin.yPx = 0;
    end
end

function T = buildStepTable(payload, angles, coordinateUnit)
    stepCount = numel(payload.liftOffFrame);
    T = table();
    T.step_index = (1:stepCount).';
    T.is_valid = payload.isValid(:);
    T.invalid_reason = payload.invalidReason(:);
    T.lift_off_frame = payload.liftOffFrame(:);
    T.landing_frame = payload.landingFrame(:);
    T.swing_time_s = payload.stepTime(:);
    T.cycle_time_s = payload.cycleTime(:);
    T.stance_time_s = payload.stanceTime(:);
    T.cadence_per_min = payload.cadence(:);
    T.duty_factor = payload.dutyFactor(:);
    T.coordinate_unit = repmat(string(coordinateUnit), stepCount, 1);
    T.step_length = payload.stepLength(:);
    roleNames = ["iliac", "hip", "knee", "ankle", "foot"];
    for p = 1:numel(roleNames)
        T.(char(roleNames(p) + "_translation")) = payload.translations(:, p);
    end
    T.hip_rom_deg = payload.rom(:, 1);
    T.knee_rom_deg = payload.rom(:, 2);
    T.ankle_rom_deg = payload.rom(:, 3);
    T.hip_min_deg = payload.angleMin(:, 1);
    T.hip_max_deg = payload.angleMax(:, 1);
    T.knee_min_deg = payload.angleMin(:, 2);
    T.knee_max_deg = payload.angleMax(:, 2);
    T.ankle_min_deg = payload.angleMin(:, 3);
    T.ankle_max_deg = payload.angleMax(:, 3);
    T.global_hip_min_deg = repmat(finiteMin(angles.hip), stepCount, 1);
    T.global_hip_max_deg = repmat(finiteMax(angles.hip), stepCount, 1);
    T.global_knee_min_deg = repmat(finiteMin(angles.knee), stepCount, 1);
    T.global_knee_max_deg = repmat(finiteMax(angles.knee), stepCount, 1);
    T.global_ankle_min_deg = repmat(finiteMin(angles.ankle), stepCount, 1);
    T.global_ankle_max_deg = repmat(finiteMax(angles.ankle), stepCount, 1);
end

function T = buildSummaryTable(result, pose, coordinateUnit)
    steps = result.stepTable;
    validRows = false(0, 1);
    if ~isempty(steps)
        validRows = steps.is_valid;
    end
    metrics = [
        "Source format";
        "Frames";
        "Points";
        "Detected steps";
        "Valid steps";
        "Coordinate unit";
        "Mean swing time s";
        "Mean step length";
        "Hip angle min deg";
        "Hip angle max deg";
        "Knee angle min deg";
        "Knee angle max deg";
        "Ankle angle min deg";
        "Ankle angle max deg"];
    values = [
        string(pose.sourceFormat);
        string(size(pose.coords, 1));
        string(numel(pose.pointNames));
        string(height(steps));
        string(sum(validRows));
        string(coordinateUnit);
        formatNumber(finiteMean(tableColumn(steps, "swing_time_s", validRows)));
        formatNumber(finiteMean(tableColumn(steps, "step_length", validRows)));
        formatNumber(finiteMin(result.frameTable.hip_angle_deg));
        formatNumber(finiteMax(result.frameTable.hip_angle_deg));
        formatNumber(finiteMin(result.frameTable.knee_angle_deg));
        formatNumber(finiteMax(result.frameTable.knee_angle_deg));
        formatNumber(finiteMin(result.frameTable.ankle_angle_deg));
        formatNumber(finiteMax(result.frameTable.ankle_angle_deg))];
    T = table(metrics, values, 'VariableNames', {'Metric', 'Value'});
end

function values = tableColumn(T, name, rows)
    if isempty(T) || ~any(string(T.Properties.VariableNames) == name)
        values = NaN(0, 1);
    elseif isempty(rows)
        values = T.(char(name));
    else
        values = T.(char(name))(rows);
    end
end

function value = finiteMean(values)
    values = values(isfinite(values));
    if isempty(values)
        value = NaN;
    else
        value = mean(values);
    end
end

function value = finiteMin(values)
    values = values(isfinite(values));
    if isempty(values)
        value = NaN;
    else
        value = min(values);
    end
end

function value = finiteMax(values)
    values = values(isfinite(values));
    if isempty(values)
        value = NaN;
    else
        value = max(values);
    end
end

function text = formatNumber(value)
    if isfinite(value)
        text = string(sprintf('%.6g', value));
    else
        text = "";
    end
end
