% Expected caller: Runtime V2 registered renderer. Inputs are one axes and a
% pure gait preview model. Side effect is limited to redrawing that axes.
function drawGaitPreview(ax, model)
    labkit.ui.plot.clear(ax, "ResetScale", true);
    if model.result.ok && model.mode == "Angles"
        drawAngles(ax, model.result.frameTable);
    elseif model.result.ok && model.mode == "Steps"
        drawSteps(ax, model.result.events);
    elseif model.pose.ok
        drawTrajectory(ax, model.pose);
    else
        ax.YDir = "normal";
        labkit.ui.plot.message(ax, "Load pose data to preview gait analysis.");
    end
end

function drawTrajectory(ax, pose)
    ax.YDir = "reverse";
    hold(ax, "on");
    for k = 1:numel(pose.pointNames)
        plot(ax, pose.coords(:, k, 1), pose.coords(:, k, 2), ...
            "DisplayName", char(pose.pointNames(k)));
    end
    hold(ax, "off");
    title(ax, "Point trajectories");
    xlabel(ax, "X (" + pose.unitName + ")");
    ylabel(ax, "Y (" + pose.unitName + ")");
    grid(ax, "on");
    legend(ax, "Location", "best");
end

function drawAngles(ax, value)
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
    title(ax, "Joint angles");
    xlabel(ax, label);
    ylabel(ax, "Angle (deg)");
    grid(ax, "on");
    legend(ax, "Location", "best");
end

function drawSteps(ax, events)
    ax.YDir = "normal";
    y = events.footRelativeX;
    x = (1:numel(y)).';
    plot(ax, x, y, "DisplayName", "Foot relative X");
    hold(ax, "on");
    plot(ax, events.contactFrames, y(events.contactFrames), "o", ...
        "DisplayName", "Contact");
    plot(ax, events.liftOffFrames, y(events.liftOffFrames), "^", ...
        "DisplayName", "Lift-off");
    hold(ax, "off");
    title(ax, "Step events");
    xlabel(ax, "Frame");
    ylabel(ax, "Foot X relative to hip");
    grid(ax, "on");
    legend(ax, "Location", "best");
end
