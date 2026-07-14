% App-owned renderer for Gait Analysis. Expected caller is LabKit runtime
% after actions update state. Side effects are limited to UI controls,
% preview axes, and result tables.
function updateWorkbenchFromState(state, ui, ~)
    renderControls(state, ui);
    renderTables(state, ui);
    renderPreview(state, ui);
end

function renderControls(state, ui)
    labkit.ui.control.setValue(ui, 'sourceSummary', char(state.sourceSummary));
    labkit.ui.control.setValue(ui, 'outputFolder', outputFolderText(state));
    labkit.ui.control.setValue(ui, 'analysisStatus', char(state.result.message));
    labkit.ui.control.setEnabled(ui, 'runAnalysis', state.pose.ok);
    labkit.ui.control.setEnabled(ui, 'exportResults', state.result.ok);
end

function text = outputFolderText(state)
    if strlength(state.outputFolder) == 0
        text = 'No output folder chosen';
    else
        text = char(state.outputFolder);
    end
end

function renderTables(state, ui)
    if state.result.ok
        ui.controls.summaryTable.table.Data = summaryData(state.result.summaryTable);
        ui.controls.stepTable.table.Data = stepPreviewData(state.result.stepTable);
    else
        ui.controls.summaryTable.table.Data = {'Status', char(state.result.message)};
        ui.controls.stepTable.table.Data = cell(0, 4);
    end
end

function data = summaryData(T)
    if isempty(T)
        data = cell(0, 2);
    else
        data = [cellstr(T.Metric), cellstr(T.Value)];
    end
end

function data = stepPreviewData(T)
    if isempty(T)
        data = cell(0, 4);
        return;
    end
    count = min(height(T), 20);
    data = cell(count, 4);
    for k = 1:count
        data{k, 1} = T.step_index(k);
        data{k, 2} = logical(T.is_valid(k));
        data{k, 3} = T.step_time_s(k);
        data{k, 4} = T.stride_length(k);
    end
end

function renderPreview(state, ui)
    ax = ui.controls.gaitAxes.primaryAxes;
    cla(ax);
    if state.result.ok && state.previewMode == "Angles"
        renderAngles(ax, state.result.frameTable);
    elseif state.result.ok && state.previewMode == "Steps"
        renderSteps(ax, state.result.events);
    elseif state.pose.ok
        renderTrajectory(ax, state.pose);
    else
        labkit.ui.plot.message(ax, 'Load pose data to preview gait analysis.');
    end
end

function renderTrajectory(ax, pose)
    coords = pose.coords;
    hold(ax, 'on');
    for p = 1:numel(pose.pointNames)
        plot(ax, coords(:, p, 1), coords(:, p, 2), ...
            'DisplayName', char(pose.pointNames(p)));
    end
    hold(ax, 'off');
    title(ax, 'Point trajectories');
    xlabel(ax, char("X (" + pose.unitName + ")"));
    ylabel(ax, char("Y (" + pose.unitName + ")"));
    grid(ax, 'on');
    legend(ax, 'Location', 'best');
end

function renderAngles(ax, T)
    x = T.time_s;
    if all(~isfinite(x))
        x = T.frame_index;
        xlabelText = 'Frame';
    else
        xlabelText = 'Time (s)';
    end
    hold(ax, 'on');
    plot(ax, x, T.hip_angle_deg, 'DisplayName', 'Hip');
    plot(ax, x, T.knee_angle_deg, 'DisplayName', 'Knee');
    plot(ax, x, T.ankle_angle_deg, 'DisplayName', 'Ankle');
    hold(ax, 'off');
    title(ax, 'Joint angles');
    xlabel(ax, xlabelText);
    ylabel(ax, 'Angle (deg)');
    grid(ax, 'on');
    legend(ax, 'Location', 'best');
end

function renderSteps(ax, events)
    y = events.footRelativeX;
    x = (1:numel(y)).';
    plot(ax, x, y, 'DisplayName', 'Foot relative X');
    hold(ax, 'on');
    plot(ax, events.contactFrames, y(events.contactFrames), 'o', ...
        'DisplayName', 'Contact');
    plot(ax, events.liftOffFrames, y(events.liftOffFrames), '^', ...
        'DisplayName', 'Lift-off');
    hold(ax, 'off');
    title(ax, 'Step events');
    xlabel(ax, 'Frame');
    ylabel(ax, 'Foot X relative to hip');
    grid(ax, 'on');
    legend(ax, 'Location', 'best');
end
