% Expected caller: Runtime V2. Input is canonical Response Review Stats state.
% Output is deterministic controls, summaries, log, and registered preview.
function view = presentWorkbench(state)
    model = presentationModel(state);
    hasInput = ~isempty(state.project.inputs.sources);
    hasMetrics = height(state.session.cache.metrics) > 0;
    hasOutput = strlength(state.session.workflow.outputFolder) > 0;
    view = struct();
    view.controls.inputFile = sourcePanel(state.project.inputs.sources);
    view.controls.outputFolder = valueSpec(outputFolderText( ...
        state.session.workflow.outputFolder));
    view.controls.loadMetrics = enabledSpec(hasInput);
    view.controls.exportMetrics = enabledSpec(hasMetrics && hasOutput);
    view.controls.statusField = valueSpec(state.session.workflow.statusMessage);
    view.controls.summaryTable = tableSpec( ...
        response_review_stats.userInterface.summaryTableData(model));
    view.controls.details = valueSpec( ...
        response_review_stats.userInterface.detailLines(model));
    view.controls.preview = valueSpec(state.session.view.previewMode);
    view.previews.preview = struct( ...
        "Renderer", "statsPreview", "Model", model);
end

function model = presentationModel(state)
    model = struct( ...
        "inputFile", sourcePath(state.project.inputs.sources), ...
        "outputFolder", state.session.workflow.outputFolder, ...
        "baselineWindowSec", state.project.parameters.baselineWindowSec, ...
        "noiseWindowSec", state.project.parameters.noiseWindowSec, ...
        "previewMode", state.session.view.previewMode, ...
        "metrics", state.session.cache.metrics, ...
        "summary", state.session.cache.summary, ...
        "aligned", state.session.cache.aligned, ...
        "statusMessage", state.session.workflow.statusMessage, ...
        "lastAction", state.session.workflow.lastAction);
end

function spec = sourcePanel(sources)
    files = struct("id", {}, "path", {}, "status", {});
    status = "No input selected";
    if ~isempty(sources)
        filepath = string(sources(1).reference.originalPath);
        files = struct("id", "item1", "path", filepath, "status", "");
        status = filepath;
    end
    spec = struct("Files", files, "Status", status);
end

function filepath = sourcePath(sources)
    filepath = "";
    if ~isempty(sources)
        filepath = string(sources(1).reference.originalPath);
    end
end

function text = outputFolderText(filepath)
    text = "No output folder selected";
    if strlength(string(filepath)) > 0
        text = string(filepath);
    end
end

function spec = valueSpec(value)
    spec = struct();
    spec.Value = value;
end

function spec = enabledSpec(value)
    spec = struct("Enabled", logical(value));
end

function spec = tableSpec(value)
    spec = struct();
    spec.Data = value;
end
