% Expected caller: Gait Analysis plot-area renderer. Inputs are axes by ID
% and a pure gait preview model. Side effects are limited to those axes.
function draw(axesById, model)
axisIds = string(fieldnames(axesById));
for k = 1:numel(axisIds)
    axisId = axisIds(k);
    drawOne(axesById.(char(axisId)), withKind(model, axisId));
end
end

function model = withKind(model, kind)
model.kind = string(kind);
end

function drawOne(ax, model)
    labkit.app.plot.clearAxes(ax, "ResetScale", true);
    if ~model.pose.ok
        ax.YDir = "normal";
        labkit.app.plot.showMessage(ax, ...
            "Load pose data to preview gait analysis.");
    elseif model.kind == "skeleton"
        drawSkeletons(ax, model, false);
    elseif model.kind == "overview"
        drawSkeletons(ax, model, true);
    elseif ~model.result.ok
        ax.YDir = "normal";
        labkit.app.plot.showMessage(ax, ...
            "Run analysis to inspect one segmented step cycle.");
    elseif isempty(model.result.stepTable)
        ax.YDir = "normal";
        labkit.app.plot.showMessage(ax, ...
            "No complete lift-off to landing step was detected.");
    elseif model.kind == "angles"
        drawAngles(ax, model);
    else
        drawSegments(ax, model);
    end
    disableHitTesting(ax);
end

function drawSkeletons(ax, model, showFullRecording)
    pose = model.pose;
    [coordinates, unit] = spatialCoordinates(pose.coords, model.options);
    frames = 1:size(pose.coords, 1);
    titleText = "All overlaid skeleton trajectories";
    if ~showFullRecording && model.result.ok && ...
            ~isempty(model.result.stepTable)
        row = model.result.stepTable(model.selectedStep, :);
        frames = row.lift_off_frame:row.landing_frame;
        titleText = sprintf("Step %d | frames %d-%d", ...
            model.selectedStep, row.lift_off_frame, row.landing_frame);
    end
    ax.YDir = "reverse";
    hold(ax, "on");
    edges = pose.skeleton.edges;
    for k = 1:size(edges, 1)
        first = edges(k, 1);
        second = edges(k, 2);
        x = [coordinates(frames, first, 1), ...
            coordinates(frames, second, 1), NaN(numel(frames), 1)].';
        y = [coordinates(frames, first, 2), ...
            coordinates(frames, second, 2), NaN(numel(frames), 1)].';
        plot(ax, x(:), y(:), "-", ...
            "Color", [0.55 0.55 0.55], ...
            "HandleVisibility", "off");
    end
    for k = 1:numel(pose.pointNames)
        plot(ax, coordinates(frames, k, 1), coordinates(frames, k, 2), ...
            ".-", ...
            "DisplayName", char(pose.pointNames(k)));
    end
    hold(ax, "off");
    title(ax, titleText);
    xlabel(ax, "X (" + unit + ")");
    ylabel(ax, "Y (" + unit + ")");
    grid(ax, "on");
    legend(ax, "Location", "best");
    labkit.app.plot.fitAxesToGraphics(ax, EqualDataUnits=true);
end

function [coordinates, unit] = spatialCoordinates(coordinates, options)
    % Gait source coordinates are pixels; the current calibration defines
    % the physical display coordinate without changing the image origin.
    pixelsPerUnit = double(options.pixelsPerUnit);
    unit = string(options.unitName);
    calibrated = isscalar(pixelsPerUnit) && isfinite(pixelsPerUnit) && ...
        pixelsPerUnit > 0 && isscalar(unit) && strlength(unit) > 0;
    if calibrated
        coordinates = double(coordinates) ./ pixelsPerUnit;
    else
        unit = "px";
    end
end

function drawAngles(ax, model)
    value = selectedFrames(model);
    ax.YDir = "normal";
    x = value.time_s;
    label = "Time (s)";
    if all(~isfinite(x))
        x = value.frame_index;
        label = "Frame";
    end
    hold(ax, "on");
    plot(ax, x, value.hip_angle_deg, "DisplayName", "Hip");
    plot(ax, x, value.knee_angle_deg, "DisplayName", "Knee");
    plot(ax, x, value.ankle_angle_deg, "DisplayName", "Ankle");
    hold(ax, "off");
    title(ax, sprintf("Step %d joint angles", model.selectedStep));
    xlabel(ax, label);
    ylabel(ax, "Angle (deg)");
    grid(ax, "on");
    legend(ax, "Location", "best");
    labkit.app.plot.fitAxesToGraphics(ax);
end

function drawSegments(ax, model)
    value = selectedFrames(model);
    ax.YDir = "normal";
    x = value.time_s;
    label = "Time (s)";
    if all(~isfinite(x))
        x = value.frame_index;
        label = "Frame";
    end
    hold(ax, "on");
    plot(ax, x, value.iliac_hip_length, "DisplayName", "Iliac-Hip");
    plot(ax, x, value.hip_knee_length, "DisplayName", "Hip-Knee");
    plot(ax, x, value.knee_ankle_length, "DisplayName", "Knee-Ankle");
    plot(ax, x, value.ankle_foot_length, "DisplayName", "Ankle-Foot");
    hold(ax, "off");
    title(ax, sprintf("Step %d segment lengths", model.selectedStep));
    xlabel(ax, label);
    unit = model.result.stepTable.coordinate_unit(model.selectedStep);
    ylabel(ax, "Length (" + unit + ")");
    grid(ax, "on");
    legend(ax, "Location", "best");
    labkit.app.plot.fitAxesToGraphics(ax);
end

function value = selectedFrames(model)
    row = model.result.stepTable(model.selectedStep, :);
    value = model.result.frameTable( ...
        row.lift_off_frame:row.landing_frame, :);
end

function disableHitTesting(ax)
graphics = allchild(ax);
for k = 1:numel(graphics)
    if isprop(graphics(k), "HitTest")
        graphics(k).HitTest = "off";
    end
    if isprop(graphics(k), "PickableParts")
        graphics(k).PickableParts = "none";
    end
end
end
