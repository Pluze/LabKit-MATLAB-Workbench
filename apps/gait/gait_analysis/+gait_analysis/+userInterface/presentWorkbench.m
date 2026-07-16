% Expected caller: Runtime V2. Input is canonical gait state. Output is pure
% controls, result tables, log, and one registered preview model.
function view = presentWorkbench(state)
    pose = state.session.cache.pose;
    result = state.project.results.analysis;
    view = struct();
    view.controls.poseFile = sourcePanel(state.project.inputs.sources);
    view.controls.sourceSummary = valueSpec(sourceSummary(pose));
    view.controls.outputFolder = valueSpec(outputFolderText( ...
        state.session.workflow.outputFolder));
    view.controls.analysisStatus = valueSpec(result.message);
    view.controls.runAnalysis = enabledSpec(pose.ok);
    view.controls.exportResults = enabledSpec(result.ok);
    stepCount = height(result.stepTable);
    selectedStep = min(max(1, double( ...
        state.session.selection.currentStepIndex)), max(1, stepCount));
    view.controls.previousStep = enabledSpec(result.ok && selectedStep > 1);
    view.controls.nextStep = enabledSpec(result.ok && selectedStep < stepCount);
    if result.ok
        view.controls.summaryTable = tableSpec(summaryData(result.summaryTable));
        view.controls.stepTable = tableSpec(stepPreviewData(result.stepTable));
    else
        view.controls.summaryTable = tableSpec({'Status', char(result.message)});
        view.controls.stepTable = tableSpec(cell(0, 4));
    end
    base = struct("pose", pose, "result", result, ...
        "selectedStep", selectedStep);
    view.previews.gaitAxes.Axes.skeleton = axisSpec(base, "skeleton");
    view.previews.gaitAxes.Axes.angles = axisSpec(base, "angles");
    view.previews.gaitAxes.Axes.segments = axisSpec(base, "segments");
end

function spec = axisSpec(model, kind)
    model.kind = string(kind);
    spec = struct("Renderer", "gaitPreview", "Model", model);
end

function spec = sourcePanel(sources)
    files = struct("id", {}, "path", {}, "status", {});
    status = "No pose file loaded";
    if ~isempty(sources)
        filepath = string(sources(1).reference.originalPath);
        files = struct("id", "item1", "path", filepath, "status", "");
        status = filepath;
    end
    spec = struct("Files", files, "Status", status);
end

function text = sourceSummary(pose)
    text = "No pose file loaded";
    if pose.ok
        text = string(sprintf('%d frames | %d points | %.6g Hz | %s | unit %s', ...
            size(pose.coords, 1), numel(pose.pointNames), ...
            pose.frameRate, pose.sourceFormat, pose.unitName));
    end
end

function text = outputFolderText(folder)
    text = "No output folder chosen";
    if strlength(string(folder)) > 0
        text = string(folder);
    end
end

function data = summaryData(value)
    data = cell(0, 2);
    if ~isempty(value)
        data = [cellstr(value.Metric), cellstr(value.Value)];
    end
end

function data = stepPreviewData(value)
    count = height(value);
    data = cell(count, 4);
    for k = 1:count
        data{k, 1} = value.step_index(k);
        data{k, 2} = logical(value.is_valid(k));
        data{k, 3} = value.swing_time_s(k);
        data{k, 4} = value.step_length(k);
    end
end

function spec = valueSpec(value)
    spec = struct();
    spec.Value = value;
end

function spec = tableSpec(value)
    spec = struct();
    spec.Data = value;
end

function spec = enabledSpec(value)
    spec = struct("Enabled", logical(value));
end
