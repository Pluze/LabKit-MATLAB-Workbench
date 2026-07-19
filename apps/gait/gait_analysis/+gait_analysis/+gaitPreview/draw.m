% Expected caller: Gait Analysis plot-area renderer. Inputs are axes by ID
% and a pure gait preview model. Side effects are limited to those axes.
function draw(axesById, model)
drawOne(axesById.skeleton, withKind(model, "skeleton"));
drawOne(axesById.angles, withKind(model, "angles"));
drawOne(axesById.segments, withKind(model, "segments"));
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
        drawSkeletons(ax, model);
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
end

function drawSkeletons(ax, model)
    pose = model.pose;
    frames = 1:size(pose.coords, 1);
    titleText = "All overlaid skeleton trajectories";
    if model.result.ok && ~isempty(model.result.stepTable)
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
        x = [pose.coords(frames, first, 1), ...
            pose.coords(frames, second, 1), NaN(numel(frames), 1)].';
        y = [pose.coords(frames, first, 2), ...
            pose.coords(frames, second, 2), NaN(numel(frames), 1)].';
        plot(ax, x(:), y(:), "-", "Color", [0.55 0.55 0.55]);
    end
    for k = 1:numel(pose.pointNames)
        plot(ax, pose.coords(frames, k, 1), pose.coords(frames, k, 2), ...
            ".-", ...
            "DisplayName", char(pose.pointNames(k)));
    end
    hold(ax, "off");
    title(ax, titleText);
    xlabel(ax, "Pixel X");
    ylabel(ax, "Pixel Y");
    grid(ax, "on");
    legend(ax, "Location", "best");
    if model.result.ok && ~isempty(model.result.stepTable)
        addStepAnnotation(ax, model.result.stepTable(model.selectedStep, :));
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
end

function value = selectedFrames(model)
    row = model.result.stepTable(model.selectedStep, :);
    value = model.result.frameTable( ...
        row.lift_off_frame:row.landing_frame, :);
end

function addStepAnnotation(ax, row)
    unit = char(row.coordinate_unit);
    lines = [ ...
        sprintf("Swing %.4g s | step length %.4g %s", ...
            row.swing_time_s, row.step_length, unit); ...
        sprintf("Translation (%s): iliac %.4g, hip %.4g, knee %.4g", ...
            unit, row.iliac_translation, row.hip_translation, row.knee_translation); ...
        sprintf("ankle %.4g, foot %.4g %s", ...
            row.ankle_translation, row.foot_translation, unit); ...
        sprintf("Hip %.4g-%.4g deg (ROM %.4g)", ...
            row.hip_min_deg, row.hip_max_deg, row.hip_rom_deg); ...
        sprintf("Knee %.4g-%.4g deg (ROM %.4g)", ...
            row.knee_min_deg, row.knee_max_deg, row.knee_rom_deg); ...
        sprintf("Ankle %.4g-%.4g deg (ROM %.4g)", ...
            row.ankle_min_deg, row.ankle_max_deg, row.ankle_rom_deg)];
    text(ax, 0.01, 0.99, strjoin(lines, newline), ...
        "Units", "normalized", "VerticalAlignment", "top", ...
        "BackgroundColor", [1 1 1], "Margin", 3, ...
        "Interpreter", "none");
end
