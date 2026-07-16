function result = computeGait(pose, opts)
%COMPUTEGAIT Calculate joint, segment, stride, and step-quality measurements.
%
% Usage:
%   result = gait_analysis.analysisRun.computeGait(pose, opts)
%
% Description:
%   Analyzes named two-dimensional pose coordinates without opening the app.
%   The function maps five anatomical roles to source points, smooths their
%   coordinates, calculates joint angles and segment lengths, detects repeated
%   foot-contact cycles, evaluates each cycle against quality thresholds, and
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
%       gait_analysis.appState.defaultOptions; missing fields use those defaults.
%
% Options:
%   iliacPoint - Case-insensitive point name assigned to the iliac role.
%       Default: "iliac".
%   hipPoint - Point name assigned to the hip role. Default: "hip".
%   kneePoint - Point name assigned to the knee role. Default: "knee".
%   anklePoint - Point name assigned to the ankle role. Default: "ankle".
%   footPoint - Point name used for contact detection and stride length.
%       Default: "foot".
%   frameRate - Frames per second used only when pose.time has no finite values.
%       A nonpositive or invalid value leaves time_s as NaN. Default: 30.
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
%   minStepFrames - Minimum contact-to-contact separation and minimum accepted
%       cycle length in frames, rounded to an integer. Default: 3.
%   maxStepFrames - Maximum accepted inclusive contact-to-contact cycle length,
%       rounded to an integer. It does not change contact detection. Default: 300.
%   minStride - Minimum accepted foot x-coordinate span in output units.
%       Default: 1.
%   maxBodyDrift - Maximum accepted hip x-coordinate span in output units.
%       Default: 1000000, which normally leaves this check inactive.
%
% Event Detection:
%   The detection trace is foot_x - hip_x after smoothing. A contact is a local
%   minimum whose value is no greater than the preceding frame and strictly
%   less than the following frame. Candidates closer than minStepFrames retain
%   the lower minimum. Each adjacent pair of contacts defines one cycle; its
%   lift-off frame is the maximum relative foot x value between those contacts.
%   This is a kinematic event definition, not a force-plate contact measurement.
%
% Measurements:
%   Hip, knee, and ankle angles are the unsigned angles from 0 to 180 degrees
%   between the two adjacent segment vectors. A zero-length or nonfinite segment
%   produces NaN. Segment lengths are Euclidean distances. For each cycle,
%   stride_length and each point translation are the finite maximum-minus-
%   minimum x coordinate, not endpoint displacement. Range of motion is the
%   corresponding finite maximum-minus-minimum joint angle.
%
% Outputs:
%   result - Scalar structure containing status, normalized options, events,
%       and four tables.
%
% Result Fields:
%   ok, message - true and "Analysis complete" after successful calculation.
%   options - Effective options after defaults, scalar cleanup, and rounding.
%   events - Structure with contactFrames, liftOffFrames, and the smoothed
%       footRelativeX detection trace.
%   frameTable - One row per frame. It contains frame/time/step membership,
%       contact and lift-off flags, coordinate unit, three joint angles, four
%       segment lengths, and scaled <point>_x/<point>_y columns.
%   coordinateTable - One row per frame with frame/time and origin metadata,
%       raw <point>__x_px/<point>__y_px columns, and scaled, optionally shifted
%       <point>__x/<point>__y columns. The unshifted origin is [0 0] in pixel
%       coordinates rather than the center of pixel [1 1].
%   stepTable - One row per adjacent contact pair. It contains validity and
%       reason, contact/lift-off frames, duration, stride, five x translations,
%       three joint ranges of motion, and recording-wide joint extrema.
%       invalid_reason is "ok", "duration_out_of_range", "stride_too_small",
%       or "body_drift_too_large".
%   summaryTable - Metric/value text table reporting source geometry, detected
%       and valid cycle counts, mean valid-cycle time and stride, and global
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
%   opts = gait_analysis.appState.defaultOptions();
%   opts.smoothWindow = 1;
%   result = gait_analysis.analysisRun.computeGait(pose, opts);
%   assert(result.ok && height(result.stepTable) == 2)
%
% See also gait_analysis.sourceFiles.readPoseFile,
%   gait_analysis.appState.defaultOptions,
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
    events = detectStepEvents(smoothCoords, role, opts);
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
    defaults = gait_analysis.appState.defaultOptions();
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
    opts.minStepFrames = finiteScalar(opts.minStepFrames, 3, 1, Inf, true);
    opts.maxStepFrames = finiteScalar(opts.maxStepFrames, Inf, 1, Inf, true);
    opts.minStride = finiteScalar(opts.minStride, 1, 0, Inf, false);
    opts.maxBodyDrift = finiteScalar(opts.maxBodyDrift, Inf, 0, Inf, false);
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

function events = detectStepEvents(coords, role, opts)
    footRelativeX = coords(:, role.foot, 1) - coords(:, role.hip, 1);
    contactFrames = localMinima(footRelativeX, opts.minStepFrames);
    liftOffFrames = zeros(max(0, numel(contactFrames) - 1), 1);
    for k = 1:numel(liftOffFrames)
        segment = footRelativeX(contactFrames(k):contactFrames(k + 1));
        [~, offset] = max(segment);
        liftOffFrames(k) = contactFrames(k) + offset - 1;
    end
    events = struct();
    events.contactFrames = contactFrames(:);
    events.liftOffFrames = liftOffFrames(:);
    events.footRelativeX = footRelativeX(:);
end

function frames = localMinima(values, minSeparation)
    values = double(values(:));
    candidates = [];
    for k = 2:numel(values)-1
        if isfinite(values(k)) && values(k) <= values(k - 1) && values(k) < values(k + 1)
            candidates(end+1, 1) = k;
        end
    end
    frames = zeros(0, 1);
    for k = 1:numel(candidates)
        candidate = candidates(k);
        if isempty(frames) || candidate - frames(end) >= minSeparation
            frames(end+1, 1) = candidate;
        elseif values(candidate) < values(frames(end))
            frames(end) = candidate;
        end
    end
end

function payload = buildStepPayload(coords, angles, events, time, opts, role, scale)
    contactFrames = events.contactFrames;
    stepCount = max(0, numel(contactFrames) - 1);
    frameCount = size(coords, 1);
    payload = struct();
    payload.startFrame = zeros(stepCount, 1);
    payload.endFrame = zeros(stepCount, 1);
    payload.liftOffFrame = zeros(stepCount, 1);
    payload.stepTime = NaN(stepCount, 1);
    payload.strideLength = NaN(stepCount, 1);
    payload.isValid = false(stepCount, 1);
    payload.invalidReason = strings(stepCount, 1);
    payload.translations = NaN(stepCount, numel(role.pointIndices));
    payload.rom = NaN(stepCount, 3);
    payload.frameStepIndex = zeros(frameCount, 1);

    for s = 1:stepCount
        startFrame = contactFrames(s);
        endFrame = contactFrames(s + 1);
        idx = startFrame:endFrame;
        payload.startFrame(s) = startFrame;
        payload.endFrame(s) = endFrame;
        payload.liftOffFrame(s) = events.liftOffFrames(s);
        payload.frameStepIndex(idx) = s;
        payload.stepTime(s) = durationForFrames(time, startFrame, endFrame);
        footX = coords(idx, role.foot, 1);
        payload.strideLength(s) = finiteSpan(footX) .* scale;
        for p = 1:numel(role.pointIndices)
            x = coords(idx, role.pointIndices(p), 1);
            payload.translations(s, p) = finiteSpan(x) .* scale;
        end
        payload.rom(s, :) = [finiteSpan(angles.hip(idx)), ...
            finiteSpan(angles.knee(idx)), finiteSpan(angles.ankle(idx))];
        [payload.isValid(s), payload.invalidReason(s)] = validateStep( ...
            endFrame - startFrame + 1, payload.strideLength(s), ...
            payload.translations(s, 2), opts);
    end
end

function value = durationForFrames(time, startFrame, endFrame)
    if numel(time) >= endFrame && isfinite(time(startFrame)) && isfinite(time(endFrame))
        value = time(endFrame) - time(startFrame);
    else
        value = NaN;
    end
end

function value = finiteSpan(values)
    values = double(values(:));
    values = values(isfinite(values));
    if isempty(values)
        value = NaN;
    else
        value = max(values) - min(values);
    end
end

function [tf, reason] = validateStep(frameSpan, strideLength, hipTranslation, opts)
    tf = true;
    reason = "ok";
    if frameSpan < opts.minStepFrames || frameSpan > opts.maxStepFrames
        tf = false;
        reason = "duration_out_of_range";
    elseif ~isfinite(strideLength) || strideLength < opts.minStride
        tf = false;
        reason = "stride_too_small";
    elseif isfinite(opts.maxBodyDrift) && isfinite(hipTranslation) && ...
            hipTranslation > opts.maxBodyDrift
        tf = false;
        reason = "body_drift_too_large";
    end
end

function T = buildFrameTable(frameIndex, time, coords, pointNames, angles, ...
        segments, frameStepIndex, events, scale, coordinateUnit)
    frameCount = numel(frameIndex);
    T = table();
    T.frame_index = frameIndex(:);
    T.time_s = time(:);
    T.step_index = frameStepIndex(:);
    T.contact_event = ismember((1:frameCount).', events.contactFrames);
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
    stepCount = numel(payload.startFrame);
    T = table();
    T.step_index = (1:stepCount).';
    T.is_valid = payload.isValid(:);
    T.invalid_reason = payload.invalidReason(:);
    T.start_frame = payload.startFrame(:);
    T.lift_off_frame = payload.liftOffFrame(:);
    T.end_frame = payload.endFrame(:);
    T.step_time_s = payload.stepTime(:);
    T.coordinate_unit = repmat(string(coordinateUnit), stepCount, 1);
    T.stride_length = payload.strideLength(:);
    roleNames = ["iliac", "hip", "knee", "ankle", "foot"];
    for p = 1:numel(roleNames)
        T.(char(roleNames(p) + "_translation")) = payload.translations(:, p);
    end
    T.hip_rom_deg = payload.rom(:, 1);
    T.knee_rom_deg = payload.rom(:, 2);
    T.ankle_rom_deg = payload.rom(:, 3);
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
        "Mean step time s";
        "Mean stride length";
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
        formatNumber(finiteMean(tableColumn(steps, "step_time_s", validRows)));
        formatNumber(finiteMean(tableColumn(steps, "stride_length", validRows)));
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
